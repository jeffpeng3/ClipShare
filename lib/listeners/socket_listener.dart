import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:clipshare/dao/device_dao.dart';
import 'package:clipshare/dao/history_dao.dart';
import 'package:clipshare/entity/dev_info.dart';
import 'package:clipshare/entity/message_data.dart';
import 'package:clipshare/handler/dev_pairing_handler.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/log.dart';
import 'package:flutter/material.dart';

import '../db/db_util.dart';
import '../util/crypto.dart';

abstract class SocketObserver {
  void onReceived(MessageData data);
}

abstract class DevAliveObserver {
  //连接成功
  void onConnected(DevInfo info);

  //断开连接
  void onDisConnected(String devId);

  //配对成功
  void onPaired(DevInfo dev, String uid, bool result);
}

class DevSocket {
  DevInfo dev;
  Socket socket;
  bool isPaired;

  DevSocket({required this.dev, required this.socket, this.isPaired = false});
}

class SocketListener {
  static const String tag = "SocketListener";
  late HistoryDao _historyDao;
  late DeviceDao _deviceDao;
  final List<SocketObserver> _socketObservers = List.empty(growable: true);
  final List<DevAliveObserver> _devAliveObservers = List.empty(growable: true);
  late RawDatagramSocket _multicastSocket;
  final Map<String, DevSocket> _devSockets = {};
  late ServerSocket _server;

  SocketListener._private();

  //单例
  static SocketListener? _singleton;

  static Future<SocketListener> get inst async =>
      _singleton ??= await SocketListener._private()._init();

  Future<SocketListener> _init() async {
    _historyDao = DBUtil.inst.historyDao;
    _deviceDao = DBUtil.inst.deviceDao;
    _multicastSocket =
        await _getSocket(Constants.multicastGroup, Constants.port);
    // 初始化，创建socket监听
    _runSocketServer();
    _sendSocketInfo();
    _multicastSocket.listen((event) async {
      final datagram = _multicastSocket.receive();
      if (datagram == null) {
        return;
      }
      Map<String, dynamic> json = jsonDecode(utf8.decode(datagram.data));
      var msg = MessageData.fromJson(json);
      var dev = msg.send;
      //是本机跳过
      if (dev.guid == App.devInfo.guid) {
        return;
      }
      switch (msg.key) {
        case MsgType.broadcastInfo:
          _onReceivedBroadcastInfo(msg, datagram);
          break;
        default:
      }
    });
    return this;
  }

  ///接收广播设备信息
  Future<void> _onReceivedBroadcastInfo(
      MessageData msg, Datagram datagram) async {
    DevInfo dev = msg.send;
    //设备已连接，跳过
    if (_devSockets.keys.contains(dev.guid)) {
      return;
    }
    Log.debug(tag, dev.name);
    //建立连接
    String ip = datagram.address.address;
    _linkSocket(dev, ip, msg.data["port"]);
  }

  ///socket建立链接
  void _linkSocket(DevInfo dev, String ip, int port) async {
    final socket = await Socket.connect(ip, port);
    Log.debug(tag, '已连接到服务器');
    _devSockets[dev.guid] = DevSocket(dev: dev, socket: socket);
    //发送本机信息给对方
    MessageData msg = MessageData(
        userId: App.userId,
        send: App.devInfo,
        key: MsgType.devInfo,
        data: {},
        recv: null);
    socket.write(msg.toJsonStr());
    _onDevConnected(dev);
    // 监听从服务器接收的消息
    socket.listen(
      (List<int> data) {
        Map<String, dynamic> json = jsonDecode(utf8.decode(data));
        var msg = MessageData.fromJson(json);
        _onSocketListened(socket, msg);
      },
      onDone: () {
        _onDevDisConnected(dev.guid);
        Log.debug(tag, "${dev.name} disConnected, id = ${dev.guid}");
        Log.debug(tag, '连接已关闭');
      },
      onError: (error) {
        // _onDevDisConnected(dev.guid);
        // PrintUtil.debug(tag, "${dev.name} disConnected, id = ${dev.guid}");
        Log.debug(tag, '发生错误: $error');
      },
      // cancelOnError: true,
    );
  }

  ///运行服务端 socket 监听
  void _runSocketServer() async {
    _server = await ServerSocket.bind('0.0.0.0', 0);
    Log.debug(
        tag, '服务器已启动，监听所有网络接口 ${_server.address.address} ${_server.port}');
    _server.listen((Socket client) {
      Log.debug(
          tag, '新连接来自 ${client.remoteAddress.address}:${client.remotePort}');

      client.listen(
        (data) {
          Map<String, dynamic> json = jsonDecode(utf8.decode(data));
          var msg = MessageData.fromJson(json);
          // 在这里处理接收到的消息，你可以根据需要进行逻辑处理
          _onSocketListened(client, msg);
        },
        onDone: () {
          Log.debug(tag, '服务端连接关闭');
          for (var devId in _devSockets.keys) {
            _onDevDisConnected(devId);
          }
        },
        onError: (error) {
          Log.debug(tag, '服务端发生错误: $error');
          // for (var devId in _devSockets.keys) {
          //   _onDevDisConnected(devId);
          // }
        },
        // cancelOnError: true,
      );
    });
  }

  ///socket消息处理
  void _onReceivedMsg(MessageData msg) {
    for (var ob in _socketObservers) {
      try {
        ob.onReceived(msg);
      } catch (e, stack) {
        Log.debug(tag, e);
        Log.debug(tag, stack);
      }
    }
  }

  ///socket 监听消息处理
  void _onSocketListened(Socket socket, MessageData msg) {
    Log.debug(tag, msg.key);
    DevInfo dev = msg.send;
    switch (msg.key) {
      case MsgType.devInfo:
        //刚建立连接，保存设备信息
        _devSockets[dev.guid] = DevSocket(dev: dev, socket: socket);
        _onDevConnected(dev);
        break;
      case MsgType.history:
      case MsgType.requestSyncMissingData:
      case MsgType.missingData:
      case MsgType.ackSync:
        _onReceivedMsg(msg);
        break;
      case MsgType.requestPairing:
        //请求配对我方，生成四位配对码
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
            });
        break;
      case MsgType.pairing:
        //请求配对我方，验证配对码
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
            recv: null);
        socket.write(result.toJsonStr());
        break;
      case MsgType.paired:
        //获取配对结果
        bool result = msg.data["result"];
        _onDevPaired(dev, msg.userId, result);
        break;
      default:
    }
  }

  ///广播本机socket端口
  void _sendSocketInfo() {
    Timer.periodic(const Duration(seconds: Constants.heartbeatsSeconds),
        (timer) {
      // 广播本机socket信息
      Map<String, dynamic> map = {"port": _server.port};
      sendMulticastMsg(MsgType.broadcastInfo, map);
    });
  }

  ///设备连接成功
  void _onDevConnected(DevInfo dev) {
    Log.debug(tag, "${dev.name} connected");
    //判断是否已经配对过
    _deviceDao.getById(dev.guid, App.userId).then((v) {
      if (v == null) return;
      _devSockets[dev.guid]?.isPaired = true;
      //连接成功且已配对，获取该设备未同步记录
      sendData(dev, MsgType.requestSyncMissingData, {});
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
  void _onDevPaired(DevInfo dev, String uid, bool result) {
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
    Log.debug(tag, "$devId disConnected");
    for (var ob in _devAliveObservers) {
      try {
        ob.onDisConnected(devId);
      } catch (e, t) {
        Log.debug(tag, "$e $t");
      }
    }
  }

  ///向指定设备发送消息
  bool sendData(DevInfo? dev, MsgType key, Map<String, dynamic> data,
      [bool onlyPaired = true]) {
    Log.debug(tag, data);
    MessageData msg = MessageData(
        userId: App.userId,
        send: App.devInfo,
        key: key,
        data: data,
        recv: null);
    if (dev == null) {
      var list = onlyPaired
          ? _devSockets.values.where((dev) => dev.isPaired)
          : _devSockets.values;
      //批量发送
      for (var skt in list) {
        skt.socket.write(msg.toJsonStr());
      }
    } else {
      //向指定设备发送消息
      DevSocket? skt = _devSockets[dev.guid];
      if (skt == null) {
        //发送的设备未连接
        Log.debug(tag, "${dev.name} 设备未连接，发送失败");
        return false;
      }
      skt.socket.write(msg.toJsonStr());
    }
    return true;
  }

  /// 发送组播消息
  void sendMulticastMsg(MsgType key, Map<String, dynamic> data,
      [DevInfo? recv]) {
    MessageData msg = MessageData(
        userId: App.userId,
        send: App.devInfo,
        key: key,
        data: data,
        recv: recv);
    try {
      _multicastSocket.send(utf8.encode(msg.toJsonStr()),
          InternetAddress(Constants.multicastGroup), Constants.port);
    } catch (e, stacktrace) {
      Log.debug(tag, "$e $stacktrace");
    }
  }

  void addSocketListener(SocketObserver observer) {
    _socketObservers.add(observer);
  }

  void removeSocketListener(SocketObserver observer) {
    _socketObservers.remove(observer);
  }

  void addDevAliveListener(DevAliveObserver observer) {
    _devAliveObservers.add(observer);
  }

  void removeDevAliveListener(DevAliveObserver observer) {
    _devAliveObservers.remove(observer);
  }

  Future<RawDatagramSocket> _getSocket(String address, [int? port]) async {
    RawDatagramSocket socket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, port ?? 0);
    socket.joinMulticast(InternetAddress(address));
    return Future.value(socket);
  }
}
