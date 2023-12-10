import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clipshare/dao/device_dao.dart';
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
  late DeviceDao deviceDao;
  final List<SocketObserver> _socketObservers = List.empty(growable: true);
  final List<DevAliveObserver> _devAliveObservers = List.empty(growable: true);
  late RawDatagramSocket _socket;
  final Map<String, DateTime> _devList = {};

  SocketListener._private();

  //单例
  static SocketListener? _singleton;

  static Future<SocketListener> get inst async =>
      _singleton ??= await SocketListener._private().init();

  Future<SocketListener> init() async {
    deviceDao = DBUtil.inst.deviceDao;
    _socket = await _getSocket(Constants.multicastGroup, Constants.port);
    // 初始化广播本机信息
    sendMulticastMsg(MsgKey.discover, {});
    _socket.listen((event) async {
      final datagram = _socket.receive();
      if (datagram == null) {
        return;
      }
      // PrintUtil.debug(tag, utf8.decode(datagram.data));
      Map<String, dynamic> json = jsonDecode(utf8.decode(datagram.data));
      var msg = MessageData.fromJson(json);
      var dev = msg.send;
      //是本机跳过
      if (dev.guid == App.devInfo.guid) {
        return;
      }
      switch (msg.key) {
        //心跳
        case MsgKey.heartbeats:
          PrintUtil.debug(tag, dev.name);
          if(!_devList.keys.contains(dev.guid)){
            onDevConnected(dev);
          }
          _devList[dev.guid] = DateTime.now();
          break;
        case MsgKey.history:
          for (var ob in _socketObservers) {
            try {
              ob.onReceived(msg);
            } catch (e, stack) {
              PrintUtil.debug(tag, e);
              PrintUtil.debug(tag, stack);
            }
          }
          break;
        case MsgKey.ackSync:
          break;
        //设备发现
        case MsgKey.discover:
          Device? dbDev = await deviceDao.getById(dev.guid, msg.userId);
          if (dbDev == null) {
            //新设备
            bool res = await deviceDao.add(Device(
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
          _devList[dev.guid] = DateTime.now();
          onDevConnected(dev);
          return;
      }
    });
    sendHeartbeats();
    testDevAlive();
    return this;
  }

  void sendHeartbeats() {
    Timer.periodic(const Duration(seconds: Constants.heartbeatsSeconds),
        (timer) {
      PrintUtil.debug(tag, "sendHeartbeats");
      sendMulticastMsg(MsgKey.heartbeats, {});
    });
  }

  void testDevAlive() {
    Timer.periodic(const Duration(seconds: Constants.heartbeatsSeconds * 2),
        (timer) {
      PrintUtil.debug(tag, "testDevAlive");
      //当前毫秒值
      var now = DateTime.now().millisecondsSinceEpoch;
      var offset = Constants.heartbeatsSeconds * 2 * 1000;
      for (var devId in List.of(_devList.keys)) {
        var t = _devList[devId]!.millisecondsSinceEpoch;
        //当前时间-上次测量时间大于两倍心跳时间则认定是离线
        if (now - t > offset) {
          _devList.remove(devId);
          for (var ob in _devAliveObservers) {
            try {
              PrintUtil.debug(tag, "$devId disConnected");
              ob.onDisConnected(devId);
            } catch (e, t) {
              PrintUtil.debug(tag, "$e $t");
            }
          }
        }
      }
    });
  }
  void onDevConnected(DevInfo dev){
    PrintUtil.debug(tag, "${dev.name} connected");
    for (var ob in _devAliveObservers) {
      try {
        ob.onConnected(dev);
      } catch (e, t) {
        PrintUtil.debug(tag, "$e $t");
      }
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
      _socket.send(utf8.encode(json), InternetAddress(Constants.multicastGroup),
          Constants.port);
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
