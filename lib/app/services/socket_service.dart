import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:clipshare/app/data/enums/connection_mode.dart';
import 'package:clipshare/app/data/enums/forward_msg_type.dart';
import 'package:clipshare/app/data/models/dev_info.dart';
import 'package:clipshare/app/data/models/message_data.dart';
import 'package:clipshare/app/data/models/version.dart';
import 'package:clipshare/app/handlers/dev_pairing_handler.dart';
import 'package:clipshare/app/handlers/socket/forward_socket_client.dart';
import 'package:clipshare/app/handlers/socket/secure_socket_client.dart';
import 'package:clipshare/app/handlers/socket/secure_socket_server.dart';
import 'package:clipshare/app/handlers/sync/file_sync_handler.dart';
import 'package:clipshare/app/handlers/sync/missing_data_sync_handler.dart';
import 'package:clipshare/app/handlers/task_runner.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/crypto.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

abstract class DevAliveListener {
  //连接成功
  void onConnected(
    DevInfo info,
    AppVersion minVersion,
    AppVersion version,
    bool isForward,
  );

  //断开连接
  void onDisConnected(String devId);

  //配对成功
  void onPaired(DevInfo dev, int uid, bool result, String? address);

  //取消配对
  void onCancelPairing(DevInfo dev);

  //忘记设备
  void onForget(DevInfo dev, int uid);
}

abstract class SyncListener {
  //同步数据
  Future onSync(MessageData msg);

  //确认同步
  Future ackSync(MessageData msg);
}

abstract class DiscoverListener {
  //开始
  void onDiscoverStart();

  //结束
  void onDiscoverFinished();
}

abstract class ForwardStatusListener {
  void onForwardServerConnected();

  void onForwardServerDisconnected();
}

class DevSocket {
  DevInfo dev;
  SecureSocketClient socket;
  bool isPaired;
  AppVersion? minVersion;
  AppVersion? version;
  DateTime? lastPingTime;

  DevSocket({
    required this.dev,
    required this.socket,
    this.isPaired = false,
    this.minVersion,
    this.version,
  });

  void updatePingTime() {
    lastPingTime = DateTime.now();
  }
}

class MissingDataSyncProgress {
  int seq;
  int syncedCount = 1;
  int total;

  MissingDataSyncProgress(this.seq, this.total);

  MissingDataSyncProgress copy() {
    return MissingDataSyncProgress(seq, total)..syncedCount = syncedCount;
  }

  bool get hasCompleted => syncedCount >= total;
}

class SocketService extends GetxService {
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  static const String tag = "SocketService";
  final Map<Module, List<SyncListener>> _syncListeners = {};
  Timer? _heartbeatTimer;
  Timer? _forwardClientHeartbeatTimer;
  DateTime? _lastForwardServerPingTime;
  final List<DevAliveListener> _devAliveListeners = List.empty(growable: true);
  final List<DiscoverListener> _discoverListeners = List.empty(growable: true);
  final List<ForwardStatusListener> _forwardStatusListener =
      List.empty(growable: true);
  final missingDataSyncProgress = <String, MissingDataSyncProgress>{}.obs;
  final Map<String, DevSocket> _devSockets = {};
  late SecureSocketServer _server;
  ForwardSocketClient? _forwardClient;

  //临时记录链接配对自定义ip设备记录
  final Set<String> ipSetTemp = {};
  final Set<String> _connectingAddress = {};
  final Map<int, FileSyncHandler> _forwardFiles = {};
  Map<String, Future> broadcastProcessChain = {};
  bool pairing = false;
  static bool _isInit = false;

  String? get forwardServerHost {
    if (!appConfig.enableForward) return null;
    return appConfig.forwardServer!.host;
  }

  int? get forwardServerPort {
    if (!appConfig.enableForward) return null;
    return appConfig.forwardServer!.port.toInt();
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
                  _onBroadcastInfoReceived(msg, datagram);
            }
            break;
          default:
        }
      });
    }
  }

  ///接收广播设备信息
  Future<void> _onBroadcastInfoReceived(
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
      onMessage: (client, json) {
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
      onMessage: (client, json) {
        var msg = MessageData.fromJson(json);
        _onSocketReceived(client, msg);
      },
      onError: (err) {
        Log.error(tag, "服务端内客户端连接，出现错误：$err");
      },
      onClientError: (e, ip, port, client) {
        //此处端口不是客户端的服务端口，是客户端的socket进程端口
        Log.error(tag, "client 出现错误 $ip $port $e");
        final keys = _devSockets.keys;
        for (var id in keys) {
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
        final keys = _devSockets.keys;
        for (var id in keys) {
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
        final keys = _devSockets.keys;
        for (var id in keys) {
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
    if (forwardServerHost == null || forwardServerPort == null) return;
    try {
      _forwardClient = await ForwardSocketClient.connect(
        ip: forwardServerHost!,
        port: forwardServerPort!,
        onMessage: (self, data) {
          Log.debug(tag, "forwardClient onMessage $data");
          _onForwardServerReceived(jsonDecode(data));
        },
        onDone: (self) {
          _forwardClient = null;
          for (var listener in _forwardStatusListener) {
            listener.onForwardServerDisconnected();
          }
          _stopJudgeForwardClientAlive();
          Log.debug(tag, "forwardClient done");
          Future.delayed(
            const Duration(milliseconds: 500),
            () => connectForwardServer(true),
          );
        },
        onError: (ex, self) {
          Log.debug(tag, "forwardClient onError $ex");
        },
        onConnected: (self) {
          Log.debug(tag, "forwardClient onConnected");
          for (var listener in _forwardStatusListener) {
            listener.onForwardServerConnected();
          }
          _startJudgeForwardClientAlivePeriod();
          //中转服务器连接成功后发送本机信息
          final connData = {
            "connType": ForwardConnType.base.name,
            "self": appConfig.device.guid,
            "platform": defaultTargetPlatform.name.upperFirst(),
            "appVersion": appConfig.version.toString(),
          };
          final key = appConfig.forwardServer?.key;
          if (key != null) {
            connData["key"] = key;
          }
          self.send(connData);
          if (startDiscovering) {
            Future.delayed(const Duration(seconds: 1), () async {
              final list = await _forwardDiscover();
              //发现中转设备
              TaskRunner<void>(
                initialTasks: list,
                onFinish: () async {},
                concurrency: 50,
              );
            });
          }
        },
      );
    } catch (e) {
      Log.debug(tag, "connect forward server failed $e");
      Future.delayed(
        const Duration(milliseconds: 500),
        () => connectForwardServer(true),
      );
    }
  }

  ///断开中转服务器
  void disConnectForwardServer() {
    _forwardClient?.close();
    _forwardClient = null;
    for (var listener in _forwardStatusListener) {
      listener.onForwardServerDisconnected();
    }
    _disconnectForwardSockets();
  }

  ///断开所有通过中转服务器的连接
  void _disconnectForwardSockets() {
    final keys = _devSockets.keys.toList();
    for (var devId in keys) {
      var skt = _devSockets[devId];
      if (skt == null || !skt.socket.isForwardMode) continue;
      _onDevDisConnected(devId);
      skt.socket.destroy();
    }
  }

  Future<void> _onForwardServerReceived(Map<String, dynamic> data) async {
    final type = ForwardMsgType.getValue(data["type"]);
    switch (type) {
      case ForwardMsgType.ping:
        _lastForwardServerPingTime = DateTime.now();
        break;
      case ForwardMsgType.fileSyncNotAllowed:
        Global.showTipsDialog(
          context: Get.context!,
          text: "连接的中转服务器不允许文件同步",
          title: "发送失败",
        );
        break;
      case ForwardMsgType.check:
        void disableForwardServerAfterDelay() {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_forwardClient != null) return;
            appConfig.setEnableForward(false);
          });
        }
        if (!data.containsKey("result")) {
          Global.showTipsDialog(
            context: Get.context!,
            text: "未知的返回结果:\n ${data.toString()}",
            title: "中转服务器连接失败",
          );
          disableForwardServerAfterDelay();
          return;
        }
        final result = data["result"];
        if (result == "success") {
          return;
        }
        disableForwardServerAfterDelay();
        Global.showTipsDialog(
          context: Get.context!,
          text: result,
          title: "中转服务器连接失败",
        );
        break;
      case ForwardMsgType.requestConnect:
        final targetId = data["sender"];
        manualConnectByForward(targetId);
        break;
      case ForwardMsgType.sendFile:
        final targetId = data["sender"];
        final size = data["size"].toString().toInt();
        final fileName = data["fileName"];
        final fileId = data["fileId"].toString().toInt();
        final userId = data["userId"].toString().toInt();
        //连接中转接收文件
        try {
          await FileSyncHandler.recFile(
            isForward: true,
            ip: forwardServerHost!,
            port: forwardServerPort!,
            size: size,
            fileName: fileName,
            devId: targetId,
            userId: userId,
            fileId: fileId,
            context: Get.context!,
            targetId: targetId,
          );
        } catch (err, stack) {
          Log.debug(
            tag,
            "receive file failed from forward"
            "$err $stack",
          );
        }
        break;
      case ForwardMsgType.fileReceiverConnected:
        //接收方已连接，开始发送
        final fileId = data["fileId"].toString().toInt();
        if (_forwardFiles.containsKey(fileId)) {
          _forwardFiles[fileId]!.onForwardReceiverConnected();
        } else {
          Log.warn(tag, "fileReceiverConnected but not fileId in waiting list");
        }
        break;
      default:
    }
  }

  ///socket 监听消息处理
  Future<void> _onSocketReceived(
    SecureSocketClient client,
    MessageData msg,
  ) async {
    assert(() {
      Log.debug(tag, msg.key);
      return true;
    }());
    DevInfo dev = msg.send;
    var address =
        ipSetTemp.firstWhereOrNull((ip) => ip.split(":")[0] == client.ip);
    switch (msg.key) {
      case MsgType.ping:
        if (_devSockets.containsKey(dev.guid)) {
          _devSockets[dev.guid]!.updatePingTime();
        }
        break;

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
        var data = msg.data["data"] as Map<dynamic, dynamic>;
        copyMsg.data = data.cast<String, dynamic>();
        final devId = dev.guid;
        final total = msg.data["total"];
        int seq = msg.data["seq"];
        //如果已经存在同步记录则更新或者移除
        if (missingDataSyncProgress.containsKey(devId)) {
          var progress = missingDataSyncProgress[devId]!;
          progress.seq = seq;
          progress.total = total;
          progress.syncedCount++;
          missingDataSyncProgress[devId] = progress.copy();
          if (progress.hasCompleted) {
            //同步完成，移除
            missingDataSyncProgress.remove(devId);
            if (missingDataSyncProgress.keys.isEmpty) {
              appConfig.isHistorySyncing.value = false;
            }
          }
        } else if (total != 1) {
          final progress = MissingDataSyncProgress(1, total);
          //否则新增
          missingDataSyncProgress[devId] = progress;
          if (!appConfig.isHistorySyncing.value) {
            appConfig.isHistorySyncing.value = true;
          }
        }
        _onSyncMsg(copyMsg);
        break;

      ///请求批量同步
      case MsgType.reqMissingData:
        // var devIds = (msg.data["devIds"] as List<dynamic>).cast<String>();
        MissingDataSyncHandler.sendMissingData(dev, [appConfig.device.guid]);
        break;

      ///请求配对我方，生成四位配对码
      case MsgType.reqPairing:
        final random = Random();
        int code = 100000 + random.nextInt(900000);
        DevPairingHandler.addCode(dev.guid, CryptoUtil.toMD5(code));
        //发送通知
        Global.notify("新配对请求");
        if (pairing) {
          Get.back();
        }
        pairing = true;
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
                    cancelPairing(dev);
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
        if (pairing = true) {
          Get.back();
          pairing = false;
        }
        break;

      ///取消配对
      case MsgType.cancelPairing:
        DevPairingHandler.removeCode(dev.guid);
        if (pairing) {
          Get.back();
        }
        _onCancelPairing(dev);
        break;

      ///文件同步
      case MsgType.file:
        String ip = client.ip;
        int port = msg.data["port"];
        int size = msg.data["size"];
        String fileName = msg.data["fileName"];
        int fileId = msg.data["fileId"];
        try {
          await FileSyncHandler.recFile(
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

  void cancelPairing(DevInfo dev) {
    if (!pairing) return;
    DevPairingHandler.removeCode(dev.guid);
    pairing = true;
    Get.back();
    sendData(dev, MsgType.cancelPairing, {});
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
          dbService.execSequentially(() => listener.onSync(msg));
          break;
        case MsgType.ackSync:
          dbService.execSequentially(() => listener.ackSync(msg));
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
    List<Future<void> Function()> tasks = [];
    if (appConfig.onlyForwardMode) {
      tasks = []; //测试屏蔽发现用
    } else {
      //先发现自添加设备
      tasks.addAll(await _customDiscover());
      //广播发现
      tasks.addAll(_multicastDiscover());
    }
    appConfig.deviceDiscoveryStatus.value = "广播发现";
    //并行处理
    _taskRunner = TaskRunner<void>(
      initialTasks: tasks,
      onFinish: () async {
        appConfig.deviceDiscoveryStatus.value = "扫描网络";
        if (appConfig.onlyForwardMode) {
          tasks = []; //测试屏蔽发现用
        } else {
          //发现子网设备
          tasks = await _subNetDiscover();
        }
        _taskRunner = TaskRunner<void>(
          initialTasks: tasks,
          onFinish: () async {
            appConfig.deviceDiscoveryStatus.value = "中转发现";
            //发现中转设备
            tasks = await _forwardDiscover();
            _taskRunner = TaskRunner<void>(
              initialTasks: tasks,
              onFinish: () async {
                appConfig.deviceDiscoveryStatus.value = null;
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
    appConfig.deviceDiscoveryStatus.value = null;
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
      if (forwardServerHost == null || forwardServerPort == null) continue;
      tasks.add(() => manualConnectByForward(dev.guid));
    }
    return tasks;
  }

  ///中转连接设备
  Future<void> manualConnectByForward(String devId) {
    return manualConnect(
      forwardServerHost!,
      port: forwardServerPort,
      forward: true,
      targetDevId: devId,
      onErr: (err) {
        Log.debug(tag, '$devId 中转连接，发生错误:$err');
        _onDevDisConnected(devId);
      },
    );
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
      onMessage: (client, json) {
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
    var minVersion = AppVersion(minName, minCode);
    var version = AppVersion(versionName, versionCode);
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
      client,
      minVersion,
      version,
      client.isForwardMode,
    );
    if (paired) {
      //已配对，请求所有缺失数据
      reqMissingData();
    }
  }

  ///判断某个设备使用使用中转
  bool isUseForward(String guid) {
    if (!_devSockets.containsKey(guid)) return false;
    return _devSockets[guid]!.socket.isForwardMode;
  }

  Future<void> reqMissingData() async {
    // var devices = await dbService.deviceDao.getAllDevices(appConfig.userId);
    // var devIds =
    //     devices.where((dev) => dev.isPaired).map((e) => e.guid).toList();
    sendData(null, MsgType.reqMissingData, {
      "devIds": [],
    });
  }

  ///设备连接成功
  void _onDevConnected(
    DevInfo dev,
    SecureSocketClient client,
    AppVersion minVersion,
    AppVersion version,
    bool useForward,
  ) async {
    final ip = client.ip;
    final port = client.port;
    //更新连接地址
    String address = "$ip:$port";
    await dbService.deviceDao
        .updateDeviceAddress(dev.guid, appConfig.userId, address);
    _devSockets[dev.guid]!.updatePingTime();
    broadcastProcessChain.remove(dev.guid);
    for (var listener in _devAliveListeners) {
      try {
        listener.onConnected(
          dev,
          minVersion,
          version,
          useForward,
        );
      } catch (e, t) {
        Log.debug(tag, "$e $t");
      }
    }
  }

  ///断开所有连接（仅调试）
  void disConnectAllConnections() async {
    if (kReleaseMode) return;
    var skts = _devSockets.values.toList();
    for (var devSkt in skts) {
      await devSkt.socket.close();
      _onDevDisConnected(devSkt.dev.guid);
    }
    _devSockets.clear();
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

  ///设备取消配对
  void _onCancelPairing(DevInfo dev) {
    Log.debug(tag, "${dev.name} cancelPairing");
    for (var listener in _devAliveListeners) {
      try {
        listener.onCancelPairing(dev);
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
    //首次直接发送
    sendData(null, MsgType.ping, {}, false);
    judgeDeviceHeartbeatTimeout();
    var interval = appConfig.heartbeatInterval;
    if (interval <= 0) return;
    //更新timer
    _heartbeatTimer = Timer.periodic(Duration(seconds: interval), (timer) {
      if (_devSockets.isEmpty) return;
      judgeDeviceHeartbeatTimeout();
      sendData(null, MsgType.ping, {}, false);
    });
  }

  ///停止所有设备的心跳测试
  void stopHeartbeatTest() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  ///定时判断中转服务连接存活状态
  void _startJudgeForwardClientAlivePeriod() {
    //先停止
    _stopJudgeForwardClientAlive();
    if (_forwardClient == null) {
      return;
    }
    //更新timer
    _forwardClientHeartbeatTimer =
        Timer.periodic(const Duration(seconds: 35), (timer) {
      var disconnected = false;
      if (_lastForwardServerPingTime == null) {
        disconnected = true;
      } else {
        final now = DateTime.now();
        if (now.difference(_lastForwardServerPingTime!).inSeconds >= 35) {
          disconnected = true;
        }
      }
      if (!disconnected) return;
      _forwardClient?.destroy();
    });
  }

  ///停止定时判断中转服务连接存活状态
  void _stopJudgeForwardClientAlive() {
    _forwardClientHeartbeatTimer?.cancel();
    _forwardClientHeartbeatTimer = null;
  }

  ///判断设备心跳是否超时
  void judgeDeviceHeartbeatTimeout() {
    var interval = appConfig.heartbeatInterval * 1.3;
    final now = DateTime.now();
    var skts = _devSockets.values.toList();
    for (var ds in skts) {
      if (ds.lastPingTime == null) {
        continue;
      }
      final diff = now.difference(ds.lastPingTime!);
      if (diff.inSeconds > interval) {
        //心跳超时
        print("judgeDeviceHeartbeatTimeout ${ds.dev.guid}");
        disconnectDevice(ds.dev, true);
      }
    }
  }

  ///设备断开连接
  void _onDevDisConnected(String devId) {
    final ds = _devSockets[devId];
    if (ds != null && ds.socket.isForwardMode) {
      final host = appConfig.forwardServer!.host;
      final port = appConfig.forwardServer!.port;
      final address = "$host:$port:$devId";
      _connectingAddress.remove(address);
    }
    //移除socket
    _devSockets.remove(devId);
    missingDataSyncProgress.remove(devId);
    if (missingDataSyncProgress.keys.isEmpty) {
      appConfig.isHistorySyncing.value = false;
    }
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
  Future<void> sendData(
    DevInfo? dev,
    MsgType key,
    Map<String, dynamic> data, [
    bool onlyPaired = true,
  ]) async {
    Iterable<DevSocket> list = [];
    //向所有设备发送消息
    if (dev == null) {
      list = onlyPaired
          ? _devSockets.values.where((dev) => dev.isPaired)
          : _devSockets.values;
      //筛选兼容版本的设备
      list = list.where(
        (dev) => dev.version != null && dev.version! >= appConfig.minVersion,
      );
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
      list = [skt];
    }
    //批量发送
    for (var skt in list) {
      MessageData msg = MessageData(
        userId: appConfig.userId,
        send: appConfig.devInfo,
        key: key,
        data: data,
        recv: null,
      );
      await skt.socket.send(msg.toJson());
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

  ///主动断开设备连接
  bool disconnectDevice(DevInfo dev, bool backSend) {
    var id = dev.guid;
    if (!_devSockets.containsKey(id)) {
      return false;
    }
    if (backSend) {
      sendData(dev, MsgType.disConnect, {});
    }
    _devSockets[id]!.socket.destroy();
    _onDevDisConnected(id);
    return true;
  }

  ///添加中转文件发送记录
  void addSendFileRecordByForward(FileSyncHandler fileSyncer, int fileId) {
    if (_forwardFiles.containsKey(fileId)) {
      throw Exception("The file is already in the sending list: $fileId");
    }
    _forwardFiles[fileId] = fileSyncer;
  }

  ///移除中转文件发送记录
  void removeSendFileRecordByForward(
    FileSyncHandler fileSyncer,
    int fileId,
    String? targetDevId,
  ) {
    _forwardFiles.remove(fileId);
    if (targetDevId != null) {
      _forwardClient?.send({
        "type": ForwardMsgType.cancelSendFile.name,
        "targetId": targetDevId,
      });
    }
  }
}
