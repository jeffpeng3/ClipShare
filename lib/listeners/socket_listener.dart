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
  void onPaired(DevInfo dev, int uid, bool result);
}

abstract class SyncObserver {
  //同步数据
  void onSync(MessageData msg);

  //确认同步
  void ackSync(MessageData msg);
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

  // late RawDatagramSocket _multicastSocket;
  List<RawDatagramSocket> _multicasts = List.empty();
  final Map<String, DevSocket> _devSockets = {};
  late ServerSocket _server;

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
    _multicasts = await _getSockets(Constants.multicastGroup, Constants.port);
    multicastDiscovery();
    for (var multicast in _multicasts) {
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
    return MySocket.connect(ip, port).then((ms) {
      Log.debug(tag, '已连接到服务器');
      var ds = DevSocket(dev: dev, socket: ms);
      _devSockets[dev.guid] = ds;
      ds.socket.listen(
        (data) {},
        onDone: () {
          _onDevDisConnected(dev.guid);
        },
        onError: (error) {
          Log.debug(tag, '发生错误: $error');
        },
      );
      _onDevConnected(dev);
      //发送本机信息给对方
      MessageData msg = MessageData(
        userId: App.userId,
        send: App.devInfo,
        key: MsgType.devInfo,
        data: {"port": _server.port},
        recv: null,
      );
      ms.send(msg.toJsonStr());
    });
  }

  ///运行服务端 socket 监听消息同步
  void _runSocketServer() async {
    _server = await ServerSocket.bind('0.0.0.0', 0);
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
  void _onSocketReceived(MySocket client, MessageData msg) {
    Log.debug(tag, msg.key);
    DevInfo dev = msg.send;
    switch (msg.key) {
      ///刚建立连接，保存设备信息
      case MsgType.devInfo:
        var port = msg.data["port"];
        MySocket.connect(client.ip, port).then((ms) {
          var ds = DevSocket(dev: dev, socket: ms);
          _devSockets[dev.guid] = ds;
          ds.socket.listen(
            (data) {},
            onDone: () {
              _onDevDisConnected(dev.guid);
            },
            onError: (error) {
              Log.debug(tag, '发生错误: $error');
            },
          );
          _onDevConnected(dev);
        });
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
        _onDevPaired(dev, msg.userId, verify);
        //返回配对结果
        MessageData result = MessageData(
          userId: App.userId,
          send: App.devInfo,
          key: MsgType.paired,
          data: {"result": verify},
          recv: null,
        );
        sendData(dev, MsgType.paired, {"result": verify});
        break;

      ///获取配对结果
      case MsgType.paired:
        bool result = msg.data["result"];
        _onDevPaired(dev, msg.userId, result);
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

  ///广播本机socket端口
  void multicastDiscovery() {
    for (var ms in const [100, 500, 2000, 5000]) {
      Future.delayed(Duration(milliseconds: ms), () {
        // 广播本机socket信息
        Map<String, dynamic> map = {"port": _server.port};
        sendMulticastMsg(MsgType.broadcastInfo, map);
      });
    }
  }

  ///设备连接成功
  void _onDevConnected(DevInfo dev) {
    Log.debug(tag, "${dev.name} connected");
    //判断是否已经配对过
    _deviceDao.getById(dev.guid, App.userId).then((v) {
      if (v == null) return;
      _devSockets[dev.guid]?.isPaired = true;
      //连接成功且已配对，获取该设备未同步记录
      sendData(dev, MsgType.reqMissingData, {});
    });
    for (var ob in _devAliveObservers) {
      try {
        ob.onConnected(dev);
      } catch (e, t) {
        Log.debug(tag, "$e $t");
      }
    }
  }

  ///设备配对成功
  void _onDevPaired(DevInfo dev, int uid, bool result) {
    Log.debug(tag, "${dev.name} paired");
    _devSockets[dev.guid]?.isPaired = true;
    for (var ob in _devAliveObservers) {
      try {
        ob.onPaired(dev, uid, result);
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
    // Log.debug(tag, data);

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
  ]) {
    MessageData msg = MessageData(
      userId: App.userId,
      send: App.devInfo,
      key: key,
      data: data,
      recv: recv,
    );
    try {
      var b64Data = CryptoUtil.base64Encode("${msg.toJsonStr()}\n");
      for (var multicast in _multicasts) {
        multicast.send(
          utf8.encode(b64Data),
          InternetAddress(Constants.multicastGroup),
          Constants.port,
        );
      }
    } catch (e, stacktrace) {
      Log.debug(tag, "$e $stacktrace");
    }
  }

  ///发送缺失记录至已连接设备
  void sendMissingData() {
    for (var ds in _devSockets.values) {
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

  Future<RawDatagramSocket> _getSocket(String multicastGroup, int port) async {
    RawDatagramSocket socket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    socket.joinMulticast(InternetAddress(multicastGroup));
    return Future.value(socket);
  }

  Future<List<RawDatagramSocket>> _getSockets(
    String multicastGroup,
    int port,
  ) async {
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
}
