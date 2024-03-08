import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:clipshare/dao/device_dao.dart';
import 'package:clipshare/entity/dev_info.dart';
import 'package:clipshare/entity/message_data.dart';
import 'package:clipshare/entity/my_socket.dart';
import 'package:clipshare/handler/dev_pairing_handler.dart';
import 'package:clipshare/handler/req_missing_data_handler.dart';
import 'package:clipshare/handler/task_runner.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/log.dart';
import 'package:flutter/material.dart';

import '../db/db_util.dart';
import '../util/crypto.dart';

abstract class DevAliveObserver {
  //连接成功
  void onConnected(DevInfo info);

  //断开连接
  void onDisConnected(String devId);

  //配对成功
  void onPaired(DevInfo dev, int uid, bool result, String? address);

  //忘记设备
  void onForget(DevInfo dev, int uid);
}

abstract class SyncObserver {
  //同步数据
  void onSync(MessageData msg);

  //确认同步
  void ackSync(MessageData msg);
}

abstract class DiscoverObserver {
  //开始
  void onDiscoverStart();

  //结束
  void onDiscoverFinished();
}

class DevSocket {
  DevInfo dev;
  MySocket socket;
  bool isPaired;

  DevSocket({required this.dev, required this.socket, this.isPaired = false});
}

class SocketListener {
  static const String tag = "SocketListener";
  late DeviceDao _deviceDao;
  final Map<Module, List<SyncObserver>> _syncObservers = {};
  final List<DevAliveObserver> _devAliveObservers = List.empty(growable: true);
  final List<DiscoverObserver> _discoverObservers = List.empty(growable: true);

  final Map<String, DevSocket> _devSockets = {};
  late ServerSocket _server;

  //临时记录链接配对自定义ip设备记录
  final Set<String> customIpSetTemp = {};

  SocketListener._private();

  //单例
  static final SocketListener _singleton = SocketListener._private();

  static SocketListener get inst => _singleton;
  static bool _isInit = false;
  Future<void> _linkQueue = Future.value();

  Future<SocketListener> init() async {
    if (_isInit) throw Exception("已初始化");
    _deviceDao = DBUtil.inst.deviceDao;
    // 初始化，创建socket监听
    _runSocketServer();
    var multicasts =
        await _getSockets(Constants.multicastGroup, Constants.port);
    startDiscoverDevice();
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
            _linkQueue =
                _linkQueue.then((v) => _onReceivedBroadcastInfo(msg, datagram));
            break;
          default:
        }
      });
    }
    _isInit = true;
    return this;
  }

  ///接收广播设备信息
  void _onReceivedBroadcastInfo(MessageData msg, Datagram datagram) {
    DevInfo dev = msg.send;
    //设备已连接，跳过
    if (_devSockets.keys.contains(dev.guid)) {
      return;
    }
    //建立连接
    String ip = datagram.address.address;
    Log.debug(tag, "${dev.name} ip: $ip，port ${msg.data["port"]}");
    return _linkAliveSocket(dev, ip, msg.data["port"]);
  }

  ///socket建立链接，确认设备存活，不需要进行数据处理
  void _linkAliveSocket(DevInfo dev, String ip, int port) async {
    //本地是否已配对
    var localDevice = await _deviceDao.getById(dev.guid, App.userId);
    var localIsPaired = localDevice?.isPaired ?? false;
    return MySocket.connect(ip, port).then((ms) {
      Log.debug(tag, '已连接到服务器');
      //发送本机信息给服务器
      MessageData msg = MessageData(
        userId: App.userId,
        send: App.devInfo,
        key: MsgType.connect,
        data: {"port": _server.port},
        recv: null,
      );
      ms.send(msg.toJsonStr());
      //保存连接
      var ds = DevSocket(dev: dev, socket: ms);
      _devSockets[dev.guid] = ds;
      //监听服务器配对状态消息
      ds.socket.listen(
        (data) {
          Map<String, dynamic> json = jsonDecode(data);
          var msg = MessageData.fromJson(json);
          switch (msg.key) {
            case MsgType.pairedStatus:
              var remoteIsPaired = msg.data["isPaired"];
              //双方配对信息一致
              if (remoteIsPaired && localIsPaired) {
                Log.debug(tag, "pairedStatusLog _linkAliveSocket isPaired");
                //已配对，获取该设备未同步记录
                _devSockets[dev.guid]!.isPaired = true;
                sendData(dev, MsgType.reqMissingData, {});
                _onDevConnected(dev);
              } else {
                Log.debug(tag, "pairedStatusLog _linkAliveSocket notPaired");
                if (localDevice != null) {
                  onDevForget(dev, App.userId);
                  _deviceDao.updateDevice(localDevice..isPaired = false);
                }
                _onDevConnected(dev);
              }
              break;
            default:
          }
        },
        onDone: () {
          _onDevDisConnected(dev.guid);
        },
        onError: (error) {
          Log.debug(tag, '发生错误: $error');
        },
      );
    });
  }

  ///运行服务端 socket 监听消息同步
  void _runSocketServer() async {
    _server = await ServerSocket.bind('0.0.0.0', Constants.port);
    Log.debug(
      tag,
      '服务器已启动，监听所有网络接口 ${_server.address.address} ${_server.port}',
    );
    _server.listen((Socket client) {
      Log.debug(
        tag,
        '新连接来自 ${client.remoteAddress.address}:${client.remotePort}',
      );
      var clientSkt = MySocket(client);
      clientSkt.listen(
        (data) {
          Map<String, dynamic> json = jsonDecode(data);
          var msg = MessageData.fromJson(json);
          _onSocketReceived(clientSkt, msg);
        },
        onError: (error) {
          Log.debug(tag, '服务端发生错误: $error');
          // for (var devId in _devSockets.keys) {
          //   _onDevDisConnected(devId);
          // }
        },
      );
    });
  }

  ///socket 监听消息处理
  void _onSocketReceived(MySocket client, MessageData msg) async {
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
        //是否服务器反向连接
        var isReverse = msg.data.containsKey('reverse');
        if (_devSockets.containsKey(dev.guid) && !isReverse) {
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
          data: {"isPaired": localIsPaired},
        ).toJsonStr();
        if (isReverse) {
          //服务器反向连接。告诉服务器配对状态
          client.send(pairedStatusData);
          break;
        }
        var port =
            msg.data.containsKey("port") ? msg.data["port"] : Constants.port;
        //告诉客户端配对状态
        client.send(pairedStatusData);
        //连接客户端服务器
        MySocket.connect(client.ip, port).then((ms) {
          var ds = DevSocket(dev: dev, socket: ms);
          _devSockets[dev.guid] = ds;
          //是客户端手动连接，发送本机信息
          if (msg.data.keys.contains("manual")) {
            //发送本机信息给对方
            MessageData msg = MessageData(
              userId: App.userId,
              send: App.devInfo,
              key: MsgType.connect,
              data: {"port": _server.port},
              recv: null,
            );
            ds.socket.send(msg.toJsonStr());
          }
          //服务器反向连接
          ms.send(
            MessageData(
              userId: App.userId,
              send: App.devInfo,
              key: MsgType.connect,
              data: {'reverse': true},
              recv: null,
            ).toJsonStr(),
          );
          //监听服务器配对状态消息
          ds.socket.listen(
            (data) async {
              Map<String, dynamic> json = jsonDecode(data);
              var msg = MessageData.fromJson(json);
              switch (msg.key) {
                case MsgType.pairedStatus:
                  var remoteIsPaired = msg.data["isPaired"];
                  //双方配对信息一致
                  if (remoteIsPaired && localIsPaired) {
                    //已配对，获取该设备未同步记录
                    _devSockets[dev.guid]!.isPaired = true;
                    sendData(dev, MsgType.reqMissingData, {});
                    _onDevConnected(dev);
                  } else {
                    if (localDevice != null) {
                      //忘记设备
                      onDevForget(dev, App.userId);
                      _deviceDao.updateDevice(localDevice..isPaired = false);
                    }
                    _onDevConnected(dev);
                  }
                  break;
                default:
              }
            },
            onDone: () {
              _onDevDisConnected(dev.guid);
            },
            onError: (error) {
              Log.debug(tag, '发生错误: $error');
            },
          );
        });
        break;

      ///主动断开连接
      case MsgType.disConnect:
        disConnectDevice(dev, false);
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
        ReqMissingDataHandler.sendMissingData(dev);
        break;

      ///请求配对我方，生成四位配对码
      case MsgType.reqPairing:
        final random = Random();
        int code = 1000 + random.nextInt(9000);
        DevPairingHandler.addCode(dev.guid, CryptoUtil.toMD5(code));
        showDialog(
          context: App.context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("配对请求"),
              content: Text("来自 ${dev.name} 的配对请求\n配对码：$code"),
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
    var lst = _syncObservers[module];
    if (lst == null) return;
    for (var ob in lst) {
      switch (msg.key) {
        case MsgType.sync:
        case MsgType.missingData:
          ob.onSync(msg);
          break;
        case MsgType.ackSync:
          ob.ackSync(msg);
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
    // if (true) return;
    if (_discovering) return;
    _discovering = true;
    if (!restart) {
      for (var ob in _discoverObservers) {
        ob.onDiscoverStart();
      }
    }
    Log.debug(tag, "开始发现设备");
    List<Future<void> Function()> tasks = _multicastDiscover();
    _taskRunner = TaskRunner<void>(
      initialTasks: tasks,
      onFinish: () async {
        _taskRunner = TaskRunner<void>(
          initialTasks: await _subNetDiscover(),
          onFinish: () {
            _taskRunner = null;
            _discovering = false;
            for (var ob in _discoverObservers) {
              ob.onDiscoverFinished();
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
      for (var ob in _discoverObservers) {
        ob.onDiscoverFinished();
      }
    }
  }

  ///重新发现设备
  void restartDiscoverDevice() async {
    Log.debug(tag, "重新开始发现设备");
    await stopDiscoverDevice(true);
    startDiscoverDevice(true);
  }

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

  ///手动连接 ip
  Future<void> manualConnect(String ip,
      {int? port, Function? onErr, Map<String, dynamic> data = const {}}) {
    return MySocket.connect(ip, port ?? Constants.port).then((ms) {
      //外部终止连接
      if (data.containsKey('stop') && data['stop'] == true) {
        ms.destroy();
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
        data: {
          "port": _server.port,
          "manual": true,
        }..addAll(data),
        recv: null,
      );
      ms.send(msg.toJsonStr());
      ms.close();
    }).catchError(onErr ?? (err) {});
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

  ///设备连接成功
  void _onDevConnected(DevInfo dev) {
    Log.debug(tag, "${dev.name} connected");
    for (var ob in _devAliveObservers) {
      try {
        ob.onConnected(dev);
      } catch (e, t) {
        Log.debug(tag, "$e $t");
      }
    }
  }

  ///设备配对成功
  void _onDevPaired(DevInfo dev, int uid, bool result, String? address) {
    Log.debug(tag, "${dev.name} paired");
    _devSockets[dev.guid]?.isPaired = true;
    for (var ob in _devAliveObservers) {
      try {
        ob.onPaired(dev, uid, result, address);
      } catch (e, t) {
        Log.debug(tag, "$e $t");
      }
    }
  }

  ///设备配对成功
  void onDevForget(DevInfo dev, int uid) {
    Log.debug(tag, "${dev.name} paired");
    _devSockets[dev.guid]?.isPaired = false;
    for (var ob in _devAliveObservers) {
      try {
        ob.onForget(dev, uid);
      } catch (e, t) {
        Log.debug(tag, "$e $t");
      }
    }
  }

  ///设备断开连接
  void _onDevDisConnected(String devId) {
    _devSockets.remove(devId);
    Log.debug(tag, "$devId 断开连接");
    for (var ob in _devAliveObservers) {
      try {
        ob.onDisConnected(devId);
      } catch (e, t) {
        Log.debug(tag, "$e $t");
      }
    }
  }

  ///向指定设备发送消息
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
    var jsonData = msg.toJsonStr();
    //向所有已配对设备发送消息
    if (dev == null) {
      var list = onlyPaired
          ? _devSockets.values.where((dev) => dev.isPaired)
          : _devSockets.values;
      //批量发送
      for (var skt in list) {
        MySocket.connect(skt.socket.ip, skt.socket.port).then((ds) {
          ds.send(jsonData);
          ds.close();
        });
      }
    } else {
      //向指定设备发送消息
      DevSocket? skt = _devSockets[dev.guid];
      if (skt == null) {
        //发送的设备未连接
        Log.debug(tag, "${dev.name} 设备未连接，发送失败");
        return;
      }
      MySocket.connect(skt.socket.ip, skt.socket.port).then((ds) {
        ds.send(jsonData);
        ds.close();
      });
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
          Constants.port,
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
      ReqMissingDataHandler.sendMissingData(ds.dev);
    }
  }

  ///添加同步监听
  void addSyncListener(Module module, SyncObserver observer) {
    if (_syncObservers.keys.contains(module)) {
      _syncObservers[module]!.add(observer);
      return;
    }
    _syncObservers[module] = List.empty(growable: true);
    _syncObservers[module]!.add(observer);
  }

  ///移除同步监听
  void removeSyncListener(Module module, SyncObserver observer) {
    _syncObservers[module]?.remove(observer);
  }

  ///添加设备连接监听
  void addDevAliveListener(DevAliveObserver observer) {
    _devAliveObservers.add(observer);
  }

  ///移除设备连接监听
  void removeDevAliveListener(DevAliveObserver observer) {
    _devAliveObservers.remove(observer);
  }

  ///添加设备发现监听
  void addDiscoverListener(DiscoverObserver observer) {
    _discoverObservers.add(observer);
  }

  ///移除设备发现监听
  void removeDiscoverListener(DiscoverObserver observer) {
    _discoverObservers.remove(observer);
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
      return true;
    }
    return false;
  }
}
