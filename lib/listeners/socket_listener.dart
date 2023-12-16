import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clipshare/dao/device_dao.dart';
import 'package:clipshare/dao/history_dao.dart';
import 'package:clipshare/entity/dev_info.dart';
import 'package:clipshare/entity/message_data.dart';
import 'package:clipshare/entity/tables/device.dart';
import 'package:clipshare/entity/tables/history.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/print_util.dart';

import '../db/db_util.dart';

abstract class SocketObserver {
  void onReceived(MessageData data);
}

abstract class DevAliveObserver {
  void onConnected(DevInfo info);

  void onDisConnected(String devId);
}

class SocketListener {
  static const String tag = "SocketListener";
  late DeviceDao _deviceDao;
  late HistoryDao _historyDao;
  final List<SocketObserver> _socketObservers = List.empty(growable: true);
  final List<DevAliveObserver> _devAliveObservers = List.empty(growable: true);
  late RawDatagramSocket _multicastSocket;
  final Map<String, Socket> _devSockets = {};
  late ServerSocket _server;

  SocketListener._private();

  //单例
  static SocketListener? _singleton;

  static Future<SocketListener> get inst async =>
      _singleton ??= await SocketListener._private()._init();

  Future<SocketListener> _init() async {
    _deviceDao = DBUtil.inst.deviceDao;
    _historyDao = DBUtil.inst.historyDao;
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
      if (msg.key == MsgKey.sendSocketInfo) {
        PrintUtil.debug(tag, dev.name);
        //设备已连接，跳过
        if (_devSockets.keys.contains(dev.guid)) {
          return;
        }
        //数据库无设备则加入数据库
        Device? dbDev = await _deviceDao.getById(dev.guid, msg.userId);
        if (dbDev == null) {
          //新设备
          bool res = await _deviceDao.add(Device(
                  guid: dev.guid,
                  devName: dev.name,
                  uid: msg.userId,
                  type: dev.type)) >
              0;
          if (!res) {
            PrintUtil.debug(tag, "Device information addition failed");
            return;
          }
        }
        //建立连接
        String ip = datagram.address.address;
        _linkSocket(dev, ip, msg.data["port"]);
      }
    });
    return this;
  }

  ///socket建立链接
  _linkSocket(DevInfo dev, String ip, int port) async {
    final socket = await Socket.connect(ip, port);
    PrintUtil.debug(tag, '已连接到服务器');
    _devSockets[dev.guid] = socket;
    _onDevConnected(dev);
    // 监听从服务器接收的消息
    socket.listen(
      (List<int> data) {
        Map<String, dynamic> json = jsonDecode(utf8.decode(data));
        var msg = MessageData.fromJson(json);
        _onSocketListen(msg);
      },
      onDone: () {
        _onDevDisConnected(dev.guid);
        PrintUtil.debug(tag, "${dev.name} disConnected, id = ${dev.guid}");
        PrintUtil.debug(tag, '连接已关闭');
      },
      onError: (error) {
        // _onDevDisConnected(dev.guid);
        // PrintUtil.debug(tag, "${dev.name} disConnected, id = ${dev.guid}");
        PrintUtil.debug(tag, '发生错误: $error');
      },
      // cancelOnError: true,
    );
  }

  void _onReceivedMsg(MessageData msg) {
    for (var ob in _socketObservers) {
      try {
        ob.onReceived(msg);
      } catch (e, stack) {
        PrintUtil.debug(tag, e);
        PrintUtil.debug(tag, stack);
      }
    }
  }

  ///运行服务端 socket 监听
  void _runSocketServer() async {
    _server = await ServerSocket.bind('0.0.0.0', 0);
    PrintUtil.debug(
        tag, '服务器已启动，监听所有网络接口 ${_server.address.address} ${_server.port}');
    _server.listen((Socket client) {
      PrintUtil.debug(
          tag, '新连接来自 ${client.remoteAddress.address}:${client.remotePort}');

      client.listen(
        (List<int> data) {
          Map<String, dynamic> json = jsonDecode(utf8.decode(data));
          var msg = MessageData.fromJson(json);
          // 在这里处理接收到的消息，你可以根据需要进行逻辑处理
          _onSocketListen(msg);
        },
        onDone: () {
          PrintUtil.debug(tag, '服务端连接关闭');
          for (var devId in _devSockets.keys) {
            _onDevDisConnected(devId);
          }
        },
        onError: (error) {
          PrintUtil.debug(tag, '服务端发生错误: $error');
          // for (var devId in _devSockets.keys) {
          //   _onDevDisConnected(devId);
          // }
        },
        // cancelOnError: true,
      );
    });
  }

  ///socket 监听消息处理
  void _onSocketListen(MessageData msg) {
    PrintUtil.debug(tag, '收到服务器消息: $msg');
    //同步确认
    if (msg.key == MsgKey.ackSync) {
      var hisId = msg.data["id"];
      _historyDao.setSync(hisId.toString(), true).then((value) {
        PrintUtil.debug(tag, "update sync $value");
        if (value == null || value == 0) return;
        _onReceivedMsg(msg);
      });
    }
    //剪贴板消息
    if (msg.key == MsgKey.history) {
      PrintUtil.debug(tag, "recv history");
      _onReceivedMsg(msg);
    }
  }

  ///广播本机socket端口
  void _sendSocketInfo() {
    Timer.periodic(const Duration(seconds: Constants.heartbeatsSeconds),
        (timer) {
      // 广播本机socket信息
      Map<String, dynamic> map = {"port": _server.port};
      sendMulticastMsg(MsgKey.sendSocketInfo, map);
    });
  }

  ///设备连接成功
  void _onDevConnected(DevInfo dev) {
    PrintUtil.debug(tag, "${dev.name} connected");
    for (var ob in _devAliveObservers) {
      try {
        ob.onConnected(dev);
      } catch (e, t) {
        PrintUtil.debug(tag, "$e $t");
      }
    }
  }

  ///设备断开连接
  void _onDevDisConnected(String devId) {
    _devSockets.remove(devId);
    PrintUtil.debug(tag, "$devId disConnected");
    for (var ob in _devAliveObservers) {
      try {
        ob.onDisConnected(devId);
      } catch (e, t) {
        PrintUtil.debug(tag, "$e $t");
      }
    }
  }

  ///发送确认同步
  void sendSyncAck(String guid, int id) {
    Socket? skt = _devSockets[guid];
    if (skt == null) {
      return;
    }
    MessageData msg = MessageData(
        userId: App.userId,
        send: App.devInfo,
        key: MsgKey.ackSync,
        data: {"id": id},
        recv: null);
    String json = jsonEncode(msg.toJson());
    skt.write(json);
  }

  ///向其他设备同步剪贴板
  void sendSyncData(History history) {
    MessageData msg = MessageData(
        userId: App.userId,
        send: App.devInfo,
        key: MsgKey.history,
        data: history.toJson(),
        recv: null);
    String json = jsonEncode(msg.toJson());
    for (var skt in _devSockets.values) {
      skt.write(json);
    }
  }

  /// 发送组播消息
  void sendMulticastMsg(MsgKey key, Map<String, dynamic> data,
      [DevInfo? recv]) {
    MessageData msg = MessageData(
        userId: App.userId,
        send: App.devInfo,
        key: key,
        data: data,
        recv: recv);
    String json = jsonEncode(msg.toJson());
    try {
      _multicastSocket.send(utf8.encode(json),
          InternetAddress(Constants.multicastGroup), Constants.port);
    } catch (e, stacktrace) {
      PrintUtil.debug(tag, "$e $stacktrace");
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
