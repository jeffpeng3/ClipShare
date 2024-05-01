import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:clipshare/dao/device_dao.dart';
import 'package:clipshare/db/app_db.dart';
import 'package:clipshare/entity/dev_info.dart';
import 'package:clipshare/entity/message_data.dart';
import 'package:clipshare/entity/settings.dart';
import 'package:clipshare/entity/version.dart';
import 'package:clipshare/handler/dev_pairing_handler.dart';
import 'package:clipshare/handler/socket/secure_socket_client.dart';
import 'package:clipshare/handler/socket/secure_socket_server.dart';
import 'package:clipshare/handler/sync_data_handler.dart';
import 'package:clipshare/handler/task_runner.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/provider/setting_provider.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/crypto.dart';
import 'package:clipshare/util/global.dart';
import 'package:clipshare/util/log.dart';
import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';

abstract class DevAliveListener {
  //连接成功
  void onConnected(DevInfo info, Version minVersion, Version version);

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

class SocketListener {
  static late Ref _ref;
  static const String tag = "SocketListener";
  late DeviceDao _deviceDao;
  final Map<Module, List<SyncListener>> _syncListeners = {};
  Timer? _heartbeatTimer;
  final List<DevAliveListener> _devAliveListeners = List.empty(growable: true);
  final List<DiscoverListener> _discoverListeners = List.empty(growable: true);

  final Map<String, DevSocket> _devSockets = {};
  late SecureSocketServer _server;

  //临时记录链接配对自定义ip设备记录
  final Set<String> customIpSetTemp = {};
  final Set<String> _connectingAddress = {};
  Map<String, Future> broadcastProcessChain = {};

  SocketListener._private();

  //单例
  static final SocketListener _singleton = SocketListener._private();

  static SocketListener get inst => _singleton;
  static bool _isInit = false;

  Settings get settings => _ref.read(settingProvider);
  List<RawDatagramSocket> multicasts = [];

  Future<SocketListener> init(Ref ref) async {
    if (_isInit) throw Exception("已初始化");
    _ref = ref;
    _deviceDao = AppDb.inst.deviceDao;
    // 初始化，创建socket监听
    _runSocketServer();
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
    multicasts = await _getSockets(Constants.multicastGroup, settings.port);
    // startDiscoverDevice();
    for (var multicast in multicasts) {
      multicast.listen((event) {
        final datagram = multicast.receive();
        if (datagram == null) {
          return;
        }
        var data = CryptoUtil.base64Decode(utf8.decode(datagram.data));
        Map<String, dynamic> json = jsonDecode(data);
        var msg = MessageData.fromJson(json);
        var dev = msg.send;
        //是本机跳过
        if (dev.guid == App.devInfo.guid) {
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

    var device = await _deviceDao.getById(dev.guid, App.userId);
    var isPaired = device != null && device.isPaired;
    //未配对且不允许被发现，结束
    if (!settings.allowDiscover && !isPaired) {
      return;
    }
    //建立连接
    String ip = datagram.address.address;
    Log.debug(tag, "${dev.name} ip: $ip，port ${msg.data["port"]}");
    return _connectFromBroadcast(dev, ip, msg.data["port"]);
  }

  ///从广播，建立 socket 链接
  Future _connectFromBroadcast(DevInfo dev, String ip, int port) {
    //已在broadcastProcessChain中添加互斥
    return SecureSocketClient.connect(
      ip: ip,
      port: port,
      prime: App.prime,
      keyPair: App.keyPair,
      onConnected: (client) async {
        Log.debug(tag, '已连接到服务器');
        //本地是否已配对
        var localDevice = await _deviceDao.getById(dev.guid, App.userId);
        var localIsPaired = localDevice?.isPaired ?? false;
        var pairedStatusData = MessageData(
          userId: App.userId,
          send: App.devInfo,
          key: MsgType.pairedStatus,
          data: {
            "isPaired": localIsPaired,
            "minVersionName": App.minVersion.name,
            "minVersionCode": App.minVersion.code,
            "versionName": App.version.name,
            "versionCode": App.version.code,
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
      onDone: () {
        Log.debug(tag, "从广播连接，服务端连接关闭");
        _onDevDisConnected(dev.guid);
      },
      onError: (error) {
        Log.debug(tag, '从广播连接，发生错误: $error');
        _onDevDisConnected(dev.guid);
      },
    );
  }

  ///运行服务端 socket 监听消息同步
  void _runSocketServer() async {
    _server = await SecureSocketServer.bind(
      ip: '0.0.0.0',
      port: settings.port,
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
      onClientError: (e, ip, port) {
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
      onClientDone: (ip, port) {
        //此处端口不是客户端的服务端口，是客户端的socket进程端口
        Log.error(tag, "client done $e $ip $port");
        for (var id in _devSockets.keys) {
          var skt = _devSockets[id]!;
          Log.error(
            tag,
            "client done skt $e ${skt.socket.ip} ${skt.socket.port}",
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

  ///socket 监听消息处理
  void _onSocketReceived(SecureSocketClient client, MessageData msg) async {
    Log.debug(tag, msg.key);
    DevInfo dev = msg.send;
    var address = "";
    var isCustom = customIpSetTemp.any((v) {
      var res = v.split(":")[0] == client.ip;
      address = v;
      return res;
    });
    switch (msg.key) {
      ///客户端连接
      case MsgType.connect:
        var device = await _deviceDao.getById(dev.guid, App.userId);
        var isPaired = device != null && device.isPaired;
        //未配对且不允许被发现，关闭链接
        if (!settings.allowDiscover && !isPaired) {
          client.destroy();
          return;
        }
        if (_devSockets.containsKey(dev.guid)) {
          //已经链接，跳过
          break;
        }
        //本地是否已配对
        var localDevice = await _deviceDao.getById(dev.guid, App.userId);
        var localIsPaired = localDevice?.isPaired ?? false;
        var pairedStatusData = MessageData(
          userId: App.userId,
          send: App.devInfo,
          key: MsgType.pairedStatus,
          data: {
            "isPaired": localIsPaired,
            "minVersionName": App.minVersion.name,
            "minVersionCode": App.minVersion.code,
            "versionName": App.version.name,
            "versionCode": App.version.code,
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
        onDevForget(dev, App.userId);
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
        SyncDataHandler.sendMissingData(dev);
        break;

      ///请求配对我方，生成四位配对码
      case MsgType.reqPairing:
        final random = Random();
        int code = 100000 + random.nextInt(900000);
        DevPairingHandler.addCode(dev.guid, CryptoUtil.toMD5(code));
        //发送通知
        Global.notify("新配对请求");
        showDialog(
          context: App.context,
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
        _onDevPaired(dev, msg.userId, verify, isCustom ? address : null);
        //返回配对结果
        sendData(dev, MsgType.paired, {"result": verify});
        customIpSetTemp.removeWhere((v) => v == address);
        break;

      ///获取配对结果
      case MsgType.paired:
        bool result = msg.data["result"];
        _onDevPaired(dev, msg.userId, result, isCustom ? address : null);
        customIpSetTemp.removeWhere((v) => v == address);
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
  void startDiscoverDevice([bool restart = false]) async {
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
    List<Future<void> Function()> tasks = await _customDiscover();
    tasks.addAll(_multicastDiscover());
    _taskRunner = TaskRunner<void>(
      initialTasks: tasks,
      onFinish: () async {
        _taskRunner = TaskRunner<void>(
          initialTasks: await _subNetDiscover(),
          onFinish: () {
            _taskRunner = null;
            _discovering = false;
            for (var listener in _discoverListeners) {
              listener.onDiscoverFinished();
            }
          },
          concurrency: 50,
        );
      },
      concurrency: 1,
    );
  }

  ///停止发现设备
  Future<void> stopDiscoverDevice([bool restart = false]) async {
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
  void restartDiscoverDevice() async {
    Log.debug(tag, "重新开始发现设备");
    await stopDiscoverDevice(true);
    startDiscoverDevice(true);
  }

  ///组播发现设备
  List<Future<void> Function()> _multicastDiscover() {
    List<Future<void> Function()> tasks = List.empty(growable: true);
    for (var ms in const [100, 500, 2000, 5000]) {
      var f = Future.delayed(Duration(milliseconds: ms), () {
        // 广播本机socket信息
        Map<String, dynamic> map = {"port": _server.port};
        sendMulticastMsg(MsgType.broadcastInfo, map);
      });
      tasks.add(() => f);
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
    var lst = await _deviceDao.getAllDevices(App.userId);
    var devices = lst.where((dev) => dev.address != null).toList();
    for (var dev in devices) {
      var [ip, port] = dev.address!.split(":");
      tasks.add(() => manualConnect(ip, port: int.parse(port)));
    }
    return tasks;
  }

  ///手动连接 ip
  Future<void> manualConnect(
    String ip, {
    int? port,
    Function? onErr,
    Map<String, dynamic> data = const {},
  }) {
    port = port ?? Constants.port;
    String address = "$ip:$port";
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
      prime: App.prime,
      keyPair: App.keyPair,
      onConnected: (SecureSocketClient client) {
        //外部终止连接
        if (data.containsKey('stop') && data['stop'] == true) {
          client.destroy();
          return;
        }
        if (data.containsKey("custom")) {
          customIpSetTemp.add("$ip:$port");
        }
        //发送本机信息给对方
        MessageData msg = MessageData(
          userId: App.userId,
          send: App.devInfo,
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
      onDone: () {
        Log.debug(tag, "手动连接关闭");
        for (var devId in _devSockets.keys) {
          var skt = _devSockets[devId]!.socket;
          if (skt.ip == ip && skt.port == port) {
            _onDevDisConnected(devId);
          }
        }
      },
      onError: (error) {
        Log.error(tag, '手动连接发生错误: $error $ip $port');
        for (var devId in _devSockets.keys) {
          var skt = _devSockets[devId]!.socket;
          if (skt.ip == ip && skt.port == port) {
            _onDevDisConnected(devId);
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
    var localDevice = await _deviceDao.getById(dev.guid, App.userId);
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
        onDevForget(dev, App.userId);
        _deviceDao.updateDevice(localDevice..isPaired = false);
        Log.debug(tag, "${dev.name} not paired");
      }
    }
    //告诉客户端配对状态
    var pairedStatusData = MessageData(
      userId: App.userId,
      send: App.devInfo,
      key: MsgType.pairedStatus,
      data: {
        "isPaired": paired,
        "minVersionName": App.minVersion.name,
        "minVersionCode": App.minVersion.code,
        "versionName": App.version.name,
        "versionCode": App.version.code,
      },
    );
    client.send(pairedStatusData.toJson());
    var minName = msg.data["minVersionName"];
    var minCode = msg.data["minVersionCode"];
    var versionName = msg.data["versionName"];
    var versionCode = msg.data["versionCode"];
    var minVersion = Version(minName, minCode);
    var version = Version(versionName, versionCode);
    Log.debug(tag,"minVersion $minVersion version $version");
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
      //已配对，获取该设备未同步记录
      sendData(dev, MsgType.reqMissingData, {});
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
    await _deviceDao.updateDeviceAddress(dev.guid, App.userId, address);
    broadcastProcessChain.remove(dev.guid);
    for (var listener in _devAliveListeners) {
      try {
        listener.onConnected(dev, minVersion,version);
      } catch (e, t) {
        Log.debug(tag, "$e $t");
      }
    }
  }

  ///设备配对成功
  void _onDevPaired(DevInfo dev, int uid, bool result, String? address) {
    Log.debug(tag, "${dev.name} paired");
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
    var interval = App.settings.heartbeatInterval;
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
      userId: App.userId,
      send: App.devInfo,
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
        (dev) => dev.version != null && dev.version! >= App.minVersion,
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
      if (skt.version! < App.minVersion) {
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
      userId: App.userId,
      send: App.devInfo,
      key: key,
      data: data,
      recv: recv,
    );
    try {
      var b64Data = CryptoUtil.base64Encode("${msg.toJsonStr()}\n");
      var multicasts = await _getSockets(Constants.multicastGroup);
      for (var multicast in multicasts) {
        multicast.send(
          utf8.encode(b64Data),
          InternetAddress(Constants.multicastGroup),
          settings.port,
        );
        multicast.close();
      }
    } catch (e, stacktrace) {
      Log.debug(tag, "$e $stacktrace");
    }
  }

  ///发送缺失记录至已连接设备
  void sendMissingData() {
    var lst = _devSockets.values.where((element) => element.isPaired);
    for (var ds in lst) {
      SyncDataHandler.sendMissingData(ds.dev);
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
