import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:clipshare/app/data/enums/connection_mode.dart';
import 'package:clipshare/app/data/repository/entity/dev_info.dart';
import 'package:clipshare/app/data/repository/entity/message_data.dart';
import 'package:clipshare/app/data/repository/entity/version.dart';
import 'package:clipshare/app/handlers/dev_pairing_handler.dart';
import 'package:clipshare/app/handlers/socket/forward_socket_client.dart';
import 'package:clipshare/app/handlers/socket/secure_socket_client.dart';
import 'package:clipshare/app/handlers/socket/secure_socket_server.dart';
import 'package:clipshare/app/handlers/sync/file_syncer.dart';
import 'package:clipshare/app/handlers/sync/missing_data_syncer.dart';
import 'package:clipshare/app/handlers/task_runner.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/crypto.dart';
import 'package:clipshare/app/utils/extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

abstract class DevAliveListener {
  //连接成功
  void onConnected(
    DevInfo info,
    Version minVersion,
    Version version,
    bool isForward,
  );

  //断开连接
  void onDisConnected(String devId);

  //配对成功
  void onPaired(DevInfo dev, int uid, bool result, String? address);

  //忘记设备
  void onForget(DevInfo dev, int uid);
}

abstract class SyncListener {
  //同步数据
  void onSync(MessageData msg);

  //确认同步
  void ackSync(MessageData msg);
}

abstract class DiscoverListener {
  //开始
  void onDiscoverStart();

  //结束
  void onDiscoverFinished();
}

abstract class ForwardStatusListener {
  void onForwardServerConnected();

  void onForwardServerDisconnect();
}

class DevSocket {
  DevInfo dev;
  SecureSocketClient socket;
  bool isPaired;
  Version? minVersion;
  Version? version;

  DevSocket({
    required this.dev,
    required this.socket,
    this.isPaired = false,
    this.minVersion,
    this.version,
  });
}

class SocketService extends GetxService {
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  static const String tag = "SocketService";
  final Map<Module, List<SyncListener>> _syncListeners = {};
  Timer? _heartbeatTimer;
  final List<DevAliveListener> _devAliveListeners = List.empty(growable: true);
  final List<DiscoverListener> _discoverListeners = List.empty(growable: true);
  final List<ForwardStatusListener> _forwardStatusListener =
      List.empty(growable: true);

  final Map<String, DevSocket> _devSockets = {};
  late SecureSocketServer _server;
  ForwardSocketClient? _forwardClient;

  //临时记录链接配对自定义ip设备记录
  final Set<String> ipSetTemp = {};
  final Set<String> _connectingAddress = {};
  Map<String, Future> broadcastProcessChain = {};

  static bool _isInit = false;

  String? get forwardServerIp {
    var arr = appConfig.forwardServer?.split(":");
    if (arr == null || arr.length < 2) return null;
    return arr[0];
  }

  int? get forwardServerPort {
    var arr = appConfig.forwardServer?.split(":");
    if (arr == null || arr.length < 2) return null;
    return arr[1].toInt();
  }

  List<RawDatagramSocket> multicasts = [];

  Future<SocketService> init() async {
    if (_isInit) throw Exception("已初始化");
    // 初始化，创建socket监听
    _runSocketServer();
    //连接中转服务器
    await connectForwardServer();
    startDiscoveringDevices();
    startHeartbeatTest();
    _isInit = true;
    return this;
  }

  ///监听广播
  Future<void> _startListenMulticast() async {
    //关闭原本的监听
    for (var multicast in multicasts) {
      multicast.close();
    }
    //重新监听
    multicasts = await _getSockets(Constants.multicastGroup, appConfig.port);
    for (var multicast in multicasts) {
      multicast.listen((event) {
        final datagram = multicast.receive();
        if (datagram == null) {
          return;
        }
        var data = CryptoUtil.base64DecodeStr(utf8.decode(datagram.data));
        Map<String, dynamic> json = jsonDecode(data);
        var msg = MessageData.fromJson(json);
        var dev = msg.send;
        //是本机跳过
        if (dev.guid == appConfig.devInfo.guid) {
          return;
        }
        switch (msg.key) {
          case MsgType.broadcastInfo:
            var devId = dev.guid;
            String ip = datagram.address.address;
            var port = msg.data["port"];
            String address = "$ip:$port";
            Future.delayed(const Duration(seconds: 5), () {
              broadcastProcessChain.remove(devId);
              _connectingAddress.remove(address);
            });
            var inChain = broadcastProcessChain.containsKey(devId);
            var connecting = _connectingAddress.contains(address);
            if (!inChain && !connecting) {
              _connectingAddress.add(address);
              broadcastProcessChain[devId] =
                  _onReceivedBroadcastInfo(msg, datagram);
            }
            break;
          default:
        }
      });
    }
  }

  ///接收广播设备信息
  Future<void> _onReceivedBroadcastInfo(
    MessageData msg,
    Datagram datagram,
  ) async {
    DevInfo dev = msg.send;
    //设备已连接，跳过
    if (_devSockets.keys.contains(dev.guid)) {
      return;
    }

    var device = await dbService.deviceDao.getById(dev.guid, appConfig.userId);
    var isPaired = device != null && device.isPaired;
    //未配对且不允许被发现，结束
    if (!appConfig.allowDiscover && !isPaired) {
      return;
    }
    //建立连接
    String ip = datagram.address.address;
    var port = msg.data["port"];
    Log.debug(tag, "${dev.name} ip: $ip，port $port");
    ipSetTemp.add("$ip:$port");
    return _connectFromBroadcast(dev, ip, msg.data["port"]);
  }

  ///从广播，建立 socket 链接
  Future _connectFromBroadcast(DevInfo dev, String ip, int port) {
    //已在broadcastProcessChain中添加互斥
    return SecureSocketClient.connect(
      ip: ip,
      port: port,
      prime1: appConfig.prime1,
      prime2: appConfig.prime2,
      onConnected: (client) async {
        Log.debug(tag, '已连接到服务器');
        //本地是否已配对
        var localDevice =
            await dbService.deviceDao.getById(dev.guid, appConfig.userId);
        var localIsPaired = localDevice?.isPaired ?? false;
        var pairedStatusData = MessageData(
          userId: appConfig.userId,
          send: appConfig.devInfo,
          key: MsgType.pairedStatus,
          data: {
            "isPaired": localIsPaired,
            "minVersionName": appConfig.minVersion.name,
            "minVersionCode": appConfig.minVersion.code,
            "versionName": appConfig.version.name,
            "versionCode": appConfig.version.code,
          },
        );
        //告诉服务器配对状态
        client.send(pairedStatusData.toJson());
      },
      onMessage: (client, data) {
        Map<String, dynamic> json = jsonDecode(data);
        var msg = MessageData.fromJson(json);
        _onSocketReceived(client, msg);
      },
      onDone: (SecureSocketClient client) {
        Log.debug(tag, "从广播连接，服务端连接关闭");
        _onDevDisConnected(dev.guid);
      },
      onError: (error, client) {
        Log.debug(tag, '从广播连接，发生错误: $error');
        _onDevDisConnected(dev.guid);
      },
    );
  }

  ///运行服务端 socket 监听消息同步
  void _runSocketServer() async {
    _server = await SecureSocketServer.bind(
      ip: '0.0.0.0',
      port: appConfig.port,
      onConnected: (ip, port) {
        Log.debug(
          tag,
          "新连接来自 ip:$ip port:$port",
        );
      },
      onMessage: (client, data) {
        Map<String, dynamic> json = jsonDecode(data);
        var msg = MessageData.fromJson(json);
        _onSocketReceived(client, msg);
      },
      onError: (err) {
        Log.error(tag, "服务端内客户端连接，出现错误：$err");
      },
      onClientError: (e, ip, port, client) {
        //此处端口不是客户端的服务端口，是客户端的socket进程端口
        Log.error(tag, "client 出现错误 $ip $port $e");
        for (var id in _devSockets.keys) {
          var skt = _devSockets[id]!;
          if (skt.socket.ip == ip) {
            _onDevDisConnected(id);
            break;
          }
        }
      },
      onClientDone: (ip, port, client) {
        //此处端口不是客户端的服务端口，是客户端的socket进程端口
        Log.error(tag, "client done $ip $port");
        for (var id in _devSockets.keys) {
          var skt = _devSockets[id]!;
          Log.error(
            tag,
            "client done skt ${skt.socket.ip} ${skt.socket.port}",
          );
          if (skt.socket.ip == ip) {
            _onDevDisConnected(id);
            break;
          }
        }
      },
      onDone: () {
        Log.debug(tag, "服务端连接关闭");
        for (var id in _devSockets.keys) {
          _onDevDisConnected(id);
        }
      },
      cancelOnError: false,
    );
    Log.debug(
      tag,
      '服务端已启动，监听所有网络接口 ${_server.ip} ${_server.port}',
    );
  }

  ///连接中转服务器
  Future<void> connectForwardServer([bool startDiscovering = false]) async {
    disConnectForwardServer();
    if (!appConfig.enableForward) return;
    if (forwardServerIp == null || forwardServerPort == null) return;
    _forwardClient = await ForwardSocketClient.connect(
      ip: forwardServerIp!,
      port: forwardServerPort!,
      onMessage: (self, data) {
        Log.debug(tag, "forwardClient onMessage $data");
      },
      onDone: (self) {
        _forwardClient = null;
        for (var listener in _forwardStatusListener) {
          listener.onForwardServerDisconnect();
        }
        Log.debug(tag, "forwardClient done");
      },
      onError: (ex, self) {
        Log.debug(tag, "forwardClient onError $ex");
      },
      onConnected: (self) {
        Log.debug(tag, "forwardClient onConnected");
        for (var listener in _forwardStatusListener) {
          listener.onForwardServerConnected();
        }
        //中转服务器连接成功后发送本机信息
        self.send({
          "connType": "keepAlive",
          "self": appConfig.device.guid,
        });
        if (startDiscovering) {
          Future.delayed(const Duration(seconds: 1), () async {
            //发现中转设备
            TaskRunner<void>(
              initialTasks: await _forwardDiscover(),
              onFinish: () async {},
              concurrency: 50,
            );
          });
        }
      },
    );
  }

  ///断开中转服务器
  void disConnectForwardServer() {
    _forwardClient?.close();
    _forwardClient = null;
    for (var listener in _forwardStatusListener) {
      listener.onForwardServerDisconnect();
    }
    for (var devId in _devSockets.keys) {
      var skt = _devSockets[devId];
      if (skt == null || !skt.socket.isForwardMode) continue;
      skt.socket.destroy();
      _onDevDisConnected(devId);
    }
  }

  ///socket 监听消息处理
  void _onSocketReceived(SecureSocketClient client, MessageData msg) async {
    Log.debug(tag, msg.key);
    DevInfo dev = msg.send;
    var address =
        ipSetTemp.firstWhereOrNull((ip) => ip.split(":")[0] == client.ip);
    switch (msg.key) {
      ///客户端连接
      case MsgType.connect:
        var device =
            await dbService.deviceDao.getById(dev.guid, appConfig.userId);
        var isPaired = device != null && device.isPaired;
        //未配对且不允许被发现，关闭链接
        if (!appConfig.allowDiscover && !isPaired) {
          client.destroy();
          return;
        }
        if (_devSockets.containsKey(dev.guid)) {
          //已经链接，跳过
          break;
        }
        //本地是否已配对
        var localDevice =
            await dbService.deviceDao.getById(dev.guid, appConfig.userId);
        var localIsPaired = localDevice?.isPaired ?? false;
        var pairedStatusData = MessageData(
          userId: appConfig.userId,
          send: appConfig.devInfo,
          key: MsgType.pairedStatus,
          data: {
            "isPaired": localIsPaired,
            "minVersionName": appConfig.minVersion.name,
            "minVersionCode": appConfig.minVersion.code,
            "versionName": appConfig.version.name,
            "versionCode": appConfig.version.code,
          },
        );
        //告诉客户端配对状态
        client.send(pairedStatusData.toJson());
        break;

      case MsgType.pairedStatus:
        _makeSurePaired(client, dev, msg);
        break;

      ///主动断开连接
      case MsgType.disConnect:
        _onDevDisConnected(dev.guid);
        break;

      ///忘记设备
      case MsgType.forgetDev:
        onDevForget(dev, appConfig.userId);
        break;

      ///单条数据同步
      case MsgType.ackSync:
      case MsgType.sync:
        _onSyncMsg(msg);
        break;

      ///批量数据同步
      case MsgType.missingData:
        var copyMsg = MessageData.fromJson(msg.toJson());
        var data = msg.data["data"];
        copyMsg.data = data;
        _onSyncMsg(copyMsg);
        break;

      ///请求批量同步
      case MsgType.reqMissingData:
        var devIds = (msg.data["devIds"] as List<dynamic>).cast<String>();
        MissingDataSyncer.sendMissingData(dev, devIds);
        break;

      ///请求配对我方，生成四位配对码
      case MsgType.reqPairing:
        final random = Random();
        int code = 100000 + random.nextInt(900000);
        DevPairingHandler.addCode(dev.guid, CryptoUtil.toMD5(code));
        //发送通知
        Global.notify("新配对请求");
        showDialog(
          context: Get.context!,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("配对请求"),
              content: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("来自 ${dev.name} 的配对请求\n配对码:"),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      code.toString().split("").join("  "),
                      style: const TextStyle(fontSize: 30),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    DevPairingHandler.removeCode(dev.guid);
                    Navigator.of(context).pop();
                  },
                  child: const Text('取消该次配对'),
                ),
              ],
            );
          },
        );
        break;

      ///请求配对我方，验证配对码
      case MsgType.pairing:
        String code = msg.data["code"];
        //验证配对码
        var verify = DevPairingHandler.verify(dev.guid, code);
        _onDevPaired(dev, msg.userId, verify, address);
        //返回配对结果
        sendData(dev, MsgType.paired, {"result": verify});
        ipSetTemp.removeWhere((v) {
          return v == address;
        });
        break;

      ///获取配对结果
      case MsgType.paired:
        bool result = msg.data["result"];
        _onDevPaired(dev, msg.userId, result, address);
        ipSetTemp.removeWhere((v) => v == address);
        break;

      ///文件同步
      case MsgType.file:
        String ip = client.ip;
        int port = msg.data["port"];
        int size = msg.data["size"];
        String fileName = msg.data["fileName"];
        int fileId = msg.data["fileId"];
        try {
          await FileSyncer.recFile(
            ip: ip,
            port: port,
            size: size,
            fileName: fileName,
            devId: msg.send.guid,
            userId: msg.userId,
            fileId: fileId,
            context: Get.context!,
          );
        } catch (err, stack) {
          Log.debug(
            tag,
            "receive file failed. ip:$ip, port: $port, size: $size, fileName: $fileName. "
            "$err $stack",
          );
        }
        break;
      default:
    }
  }

  ///数据同步处理
  void _onSyncMsg(MessageData msg) {
    Module module = Module.getValue(msg.data["module"]);
    //筛选某个模块的同步处理器
    var lst = _syncListeners[module];
    if (lst == null) return;
    for (var listener in lst) {
      switch (msg.key) {
        case MsgType.sync:
        case MsgType.missingData:
          listener.onSync(msg);
          break;
        case MsgType.ackSync:
          listener.ackSync(msg);
          break;
        default:
          break;
      }
    }
  }

  var _discovering = false;
  TaskRunner? _taskRunner;

  ///发现设备
  void startDiscoveringDevices([bool restart = false]) async {
    if (_discovering) {
      Log.debug(tag, "正在发现设备");
      return;
    }
    _discovering = true;
    if (!restart) {
      for (var listener in _discoverListeners) {
        listener.onDiscoverStart();
      }
    }
    Log.debug(tag, "开始发现设备");
    //重新更新广播监听
    await _startListenMulticast();
    //先发现自添加设备
    List<Future<void> Function()> tasks = [];
    tasks.addAll(await _customDiscover());
    //广播发现
    tasks.addAll(_multicastDiscover());
    // tasks = [];
    //并行处理
    _taskRunner = TaskRunner<void>(
      initialTasks: tasks,
      onFinish: () async {
        //发现子网设备
        tasks = await _subNetDiscover();
        // tasks = [];
        _taskRunner = TaskRunner<void>(
          initialTasks: tasks,
          onFinish: () async {
            //发现中转设备
            tasks = await _forwardDiscover();
            _taskRunner = TaskRunner<void>(
              initialTasks: tasks,
              onFinish: () async {
                _taskRunner = null;
                _discovering = false;
                for (var listener in _discoverListeners) {
                  listener.onDiscoverFinished();
                }
              },
              concurrency: 50,
            );
          },
          concurrency: 50,
        );
      },
      concurrency: 1,
    );
  }

  ///停止发现设备
  Future<void> stopDiscoveringDevices([bool restart = false]) async {
    Log.debug(tag, "停止发现设备");
    _taskRunner?.stop();
    _taskRunner = null;
    _discovering = false;
    if (!restart) {
      for (var listener in _discoverListeners) {
        listener.onDiscoverFinished();
      }
    }
  }

  ///重新发现设备
  void restartDiscoveringDevices() async {
    Log.debug(tag, "重新开始发现设备");
    await stopDiscoveringDevices(true);
    startDiscoveringDevices(true);
  }

  ///组播发现设备
  List<Future<void> Function()> _multicastDiscover() {
    List<Future<void> Function()> tasks = List.empty(growable: true);
    for (var ms in const [100, 500, 2000, 5000]) {
      f() {
        return Future.delayed(Duration(milliseconds: ms), () {
          // 广播本机socket信息
          Map<String, dynamic> map = {"port": _server.port};
          sendMulticastMsg(MsgType.broadcastInfo, map);
        });
      }

      tasks.add(() => f());
    }
    return tasks;
  }

  ///发现子网设备
  Future<List<Future<void> Function()>> _subNetDiscover() async {
    List<Future<void> Function()> tasks = List.empty(growable: true);
    var interfaces = await NetworkInterface.list();
    var expendAddress = interfaces
        .map((networkInterface) => networkInterface.addresses)
        .expand((ip) => ip);
    var ips = expendAddress
        .where((ip) => ip.type == InternetAddressType.IPv4)
        .map((address) => address.address)
        .toList();
    for (var ip in ips) {
      //生成所有 ip
      final ipList =
          List.generate(255, (i) => '${ip.split('.').take(3).join('.')}.$i')
              .where((genIp) => genIp != ip)
              .toList();
      //对每个ip尝试连接
      for (var genIp in ipList) {
        tasks.add(() => manualConnect(genIp));
      }
    }
    return tasks;
  }

  ///发现自添加设备
  Future<List<Future<void> Function()>> _customDiscover() async {
    List<Future<void> Function()> tasks = List.empty(growable: true);
    var lst = await dbService.deviceDao.getAllDevices(appConfig.userId);
    var devices = lst.where((dev) => dev.address != null).toList();
    for (var dev in devices) {
      var [ip, port] = dev.address!.split(":");
      tasks.add(() => manualConnect(ip, port: int.parse(port)));
    }
    return tasks;
  }

  ///中转连接
  Future<List<Future<void> Function()>> _forwardDiscover() async {
    List<Future<void> Function()> tasks = List.empty(growable: true);
    if (_forwardClient == null) return tasks;
    var lst = await dbService.deviceDao.getAllDevices(appConfig.userId);
    var offlineList = lst.where((dev) => !_devSockets.keys.contains(dev.guid));
    for (var dev in offlineList) {
      if (forwardServerIp == null || forwardServerPort == null) continue;
      tasks.add(
        () => manualConnect(
          forwardServerIp!,
          port: forwardServerPort,
          forward: true,
          targetDevId: dev.guid,
          onErr: (err) {
            Log.debug(tag, '${dev.guid} 中转连接，发生错误:$err');
            _onDevDisConnected(dev.guid);
          },
        ),
      );
    }
    return tasks;
  }

  ///手动连接 ip
  Future<void> manualConnect(
    String ip, {
    int? port,
    Function? onErr,
    Map<String, dynamic> data = const {},
    bool forward = false,
    String? targetDevId,
  }) {
    port = port ?? Constants.port;
    String address = "$ip:$port:$targetDevId";
    if (_connectingAddress.contains(address)) {
      return Future(() => null);
    }
    _connectingAddress.add(address);
    Future.delayed(const Duration(seconds: 5), () {
      _connectingAddress.remove(address);
    });
    return SecureSocketClient.connect(
      ip: ip,
      port: port,
      prime1: appConfig.prime1,
      prime2: appConfig.prime2,
      targetDevId: forward ? targetDevId : null,
      selfDevId: forward ? appConfig.device.guid : null,
      connectionMode: forward ? ConnectionMode.forward : ConnectionMode.direct,
      onConnected: (SecureSocketClient client) {
        //外部终止连接
        if (data.containsKey('stop') && data['stop'] == true) {
          client.destroy();
          return;
        }
        ipSetTemp.add("$ip:$port");
        //发送本机信息给对方
        MessageData msg = MessageData(
          userId: appConfig.userId,
          send: appConfig.devInfo,
          key: MsgType.connect,
          data: data,
          recv: null,
        );
        client.send(msg.toJson());
      },
      onMessage: (client, data) {
        Map<String, dynamic> json = jsonDecode(data);
        var msg = MessageData.fromJson(json);
        _onSocketReceived(client, msg);
      },
      onDone: (SecureSocketClient client) {
        Log.debug(tag, "${forward ? '中转' : '手动'}连接关闭");
        if (forward) {
          _onDevDisConnected(targetDevId!);
        } else {
          for (var devId in _devSockets.keys.toList()) {
            var skt = _devSockets[devId]!.socket;
            if (skt.ip == ip && skt.port == port) {
              _onDevDisConnected(devId);
            }
          }
        }
      },
      onError: (error, client) {
        Log.error(tag, '${forward ? '中转' : '手动'}连接发生错误: $error $ip $port');
        if (forward) {
          _onDevDisConnected(targetDevId!);
        } else {
          for (var devId in _devSockets.keys.toList()) {
            var skt = _devSockets[devId]!.socket;
            if (skt.ip == ip && skt.port == port) {
              _onDevDisConnected(devId);
            }
          }
        }
      },
    ).catchError(onErr ?? (err) => SecureSocketClient.empty);
  }

  void _makeSurePaired(
    SecureSocketClient client,
    DevInfo dev,
    MessageData msg,
  ) async {
    //已连接，结束
    if (_devSockets.containsKey(dev.guid)) {
      return;
    }
    //本地是否存在该设备
    var localDevice =
        await dbService.deviceDao.getById(dev.guid, appConfig.userId);
    bool paired = false;
    if (localDevice != null) {
      var localIsPaired = localDevice.isPaired;
      var remoteIsPaired = msg.data["isPaired"];
      //双方配对信息一致
      if (remoteIsPaired && localIsPaired) {
        paired = true;
        Log.debug(tag, "${dev.name} has paired");
      } else {
        //有一方已取消配对或未配对
        //忘记设备
        onDevForget(dev, appConfig.userId);
        dbService.deviceDao.updateDevice(localDevice..isPaired = false);
        Log.debug(tag, "${dev.name} not paired");
      }
    }
    //告诉客户端配对状态
    var pairedStatusData = MessageData(
      userId: appConfig.userId,
      send: appConfig.devInfo,
      key: MsgType.pairedStatus,
      data: {
        "isPaired": paired,
        "minVersionName": appConfig.minVersion.name,
        "minVersionCode": appConfig.minVersion.code,
        "versionName": appConfig.version.name,
        "versionCode": appConfig.version.code,
      },
    );
    client.send(pairedStatusData.toJson());
    var minName = msg.data["minVersionName"];
    var minCode = msg.data["minVersionCode"];
    var versionName = msg.data["versionName"];
    var versionCode = msg.data["versionCode"];
    var minVersion = Version(minName, minCode);
    var version = Version(versionName, versionCode);
    Log.debug(tag, "minVersion $minVersion version $version");
    //添加到本地
    if (_devSockets.containsKey(dev.guid)) {
      _devSockets[dev.guid]!.isPaired = paired;
      _devSockets[dev.guid]!.minVersion = minVersion;
      _devSockets[dev.guid]!.version = version;
    } else {
      var ds = DevSocket(
        dev: dev,
        socket: client,
        isPaired: paired,
        minVersion: minVersion,
        version: version,
      );
      _devSockets[dev.guid] = ds;
    }
    _onDevConnected(
      dev,
      client.ip,
      client.port,
      minVersion,
      version,
    );
    if (paired) {
      //已配对，请求所有缺失数据
      reqMissingData();
    }
  }

  Future<void> reqMissingData() async {
    var devices = await dbService.deviceDao.getAllDevices(appConfig.userId);
    var devIds =
        devices.where((dev) => dev.isPaired).map((e) => e.guid).toList();
    if (devIds.isNotEmpty) {
      sendData(null, MsgType.reqMissingData, {
        "devIds": devIds,
      });
    }
  }

  ///设备连接成功
  void _onDevConnected(
    DevInfo dev,
    String ip,
    int port,
    Version minVersion,
    Version version,
  ) async {
    //更新连接地址
    String address = "$ip:$port";
    await dbService.deviceDao
        .updateDeviceAddress(dev.guid, appConfig.userId, address);
    broadcastProcessChain.remove(dev.guid);
    for (var listener in _devAliveListeners) {
      try {
        listener.onConnected(
          dev,
          minVersion,
          version,
          ip == forwardServerIp,
        );
      } catch (e, t) {
        Log.debug(tag, "$e $t");
      }
    }
  }

  ///设备配对成功
  void _onDevPaired(DevInfo dev, int uid, bool result, String? address) {
    Log.debug(tag, "${dev.name} paired，address：$address");
    _devSockets[dev.guid]?.isPaired = true;
    for (var listener in _devAliveListeners) {
      try {
        listener.onPaired(dev, uid, result, address);
      } catch (e, t) {
        Log.debug(tag, "$e $t");
      }
    }
  }

  ///设备配对成功
  void onDevForget(DevInfo dev, int uid) {
    Log.debug(tag, "${dev.name} paired");
    _devSockets[dev.guid]?.isPaired = false;
    for (var listener in _devAliveListeners) {
      try {
        listener.onForget(dev, uid);
      } catch (e, t) {
        Log.debug(tag, "$e $t");
      }
    }
  }

  ///开始所有设备的心跳测试
  void startHeartbeatTest() {
    //先停止
    stopHeartbeatTest();
    var interval = appConfig.heartbeatInterval;
    if (interval <= 0) return;
    //更新timer
    _heartbeatTimer = Timer.periodic(Duration(seconds: interval), (timer) {
      if (_devSockets.isEmpty) return;
      Log.debug(tag, "send heartbeat");
      sendData(null, MsgType.heartbeat, {});
    });
  }

  ///停止所有设备的心跳测试
  void stopHeartbeatTest() {
    _heartbeatTimer?.cancel();
  }

  ///设备断开连接
  void _onDevDisConnected(String devId) {
    //移除socket
    _devSockets.remove(devId);
    //停止心跳检测
    _heartbeatTimer?.cancel();
    Log.debug(tag, "$devId 断开连接");
    for (var listener in _devAliveListeners) {
      try {
        listener.onDisConnected(devId);
      } catch (e, t) {
        Log.debug(tag, "$e $t");
      }
    }
  }

  ///向兼容的设备发送消息
  void sendData(
    DevInfo? dev,
    MsgType key,
    Map<String, dynamic> data, [
    bool onlyPaired = true,
  ]) {
    MessageData msg = MessageData(
      userId: appConfig.userId,
      send: appConfig.devInfo,
      key: key,
      data: data,
      recv: null,
    );
    //向所有设备发送消息
    if (dev == null) {
      var list = onlyPaired
          ? _devSockets.values.where((dev) => dev.isPaired)
          : _devSockets.values;
      //筛选兼容版本的设备
      list = list.where(
        (dev) => dev.version != null && dev.version! >= appConfig.minVersion,
      );
      //批量发送
      for (var skt in list) {
        skt.socket.send(msg.toJson());
      }
    } else {
      //向指定设备发送消息
      DevSocket? skt = _devSockets[dev.guid];
      if (skt == null) {
        Log.debug(tag, "${dev.name} 设备未连接，发送失败");
        return;
      }
      if (skt.version == null) {
        Log.debug(tag, "${dev.name} 设备无版本号信息，尚未准备好");
        return;
      }
      if (skt.version! < appConfig.minVersion) {
        Log.debug(tag, "${dev.name} 与当前设备版本不兼容");
        return;
      }
      skt.socket.send(msg.toJson());
    }
  }

  /// 发送组播消息
  void sendMulticastMsg(
    MsgType key,
    Map<String, dynamic> data, [
    DevInfo? recv,
  ]) async {
    MessageData msg = MessageData(
      userId: appConfig.userId,
      send: appConfig.devInfo,
      key: key,
      data: data,
      recv: recv,
    );
    try {
      var b64Data = CryptoUtil.base64EncodeStr("${msg.toJsonStr()}\n");
      var multicasts = await _getSockets(Constants.multicastGroup);
      for (var multicast in multicasts) {
        multicast.send(
          utf8.encode(b64Data),
          InternetAddress(Constants.multicastGroup),
          appConfig.port,
        );
        multicast.close();
      }
    } catch (e, stacktrace) {
      Log.debug(tag, "$e $stacktrace");
    }
  }

  ///添加同步监听
  void addSyncListener(Module module, SyncListener listener) {
    if (_syncListeners.keys.contains(module)) {
      _syncListeners[module]!.add(listener);
      return;
    }
    _syncListeners[module] = List.empty(growable: true);
    _syncListeners[module]!.add(listener);
  }

  ///移除同步监听
  void removeSyncListener(Module module, SyncListener listener) {
    _syncListeners[module]?.remove(listener);
  }

  ///添加设备连接监听
  void addDevAliveListener(DevAliveListener listener) {
    _devAliveListeners.add(listener);
  }

  ///移除设备连接监听
  void removeDevAliveListener(DevAliveListener listener) {
    _devAliveListeners.remove(listener);
  }

  ///添加设备发现监听
  void addDiscoverListener(DiscoverListener listener) {
    _discoverListeners.add(listener);
  }

  ///移除设备发现监听
  void removeDiscoverListener(DiscoverListener listener) {
    _discoverListeners.remove(listener);
  }

  ///添加中转连接状态监听
  void addForwardStatusListener(ForwardStatusListener listener) {
    _forwardStatusListener.add(listener);
  }

  ///移除中转连接状态监听
  void removeForwardStatusListener(ForwardStatusListener listener) {
    _forwardStatusListener.remove(listener);
  }

  Future<List<RawDatagramSocket>> _getSockets(
    String multicastGroup, [
    int port = 0,
  ]) async {
    final interfaces = await NetworkInterface.list();
    final sockets = <RawDatagramSocket>[];
    for (final interface in interfaces) {
      final socket =
          await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
      socket.joinMulticast(InternetAddress(multicastGroup), interface);
      sockets.add(socket);
    }
    return sockets;
  }

  ///断开主动设备连接
  bool disConnectDevice(DevInfo dev, bool backSend) {
    var id = dev.guid;
    if (_devSockets.containsKey(id)) {
      if (backSend) {
        sendData(dev, MsgType.disConnect, {});
      }
      _devSockets[id]!.socket.destroy();
      _onDevDisConnected(id);
      return true;
    }
    return false;
  }
}
