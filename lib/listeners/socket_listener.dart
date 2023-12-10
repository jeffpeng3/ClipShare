import 'dart:convert';
import 'dart:io';

import 'package:clipshare/dao/device_dao.dart';
import 'package:clipshare/entity/message_data.dart';
import 'package:clipshare/entity/tables/device.dart';
import 'package:clipshare/entity/tables/history.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/print_util.dart';

import '../db/db_util.dart';

class SocketResult {
  final NetworkInterface interface;
  final RawDatagramSocket socket;

  SocketResult(this.interface, this.socket);
}

abstract class SocketObserver {
  void onReceived(MessageData data);
}

class SocketListener {
  static const String tag = "SocketListener";
  late DeviceDao deviceDao;
  final List<SocketObserver> _observers = List.empty(growable: true);
  final List<SocketResult> _sockets = List.empty(growable: true);

  SocketListener._private();

  //单例
  static SocketListener? _singleton;

  static Future<SocketListener> get inst async =>
      _singleton ??= await SocketListener._private().init();

  Future<SocketListener> init() async {
    deviceDao = DBUtil.inst.deviceDao;
    //获取网卡信息
    _sockets
        .addAll(await _getSockets(Constants.multicastGroup, Constants.port));
    for (var socket in _sockets) {
      socket.socket.listen((event) async {
        final datagram = socket.socket.receive();
        if (datagram == null) {
          return;
        }
        Map<String, dynamic> json = jsonDecode(utf8.decode(datagram.data));
        var msg = MessageData.fromJson(json);
        var dev = msg.devInfo;
        Device? dbDev = await deviceDao.getById(dev.guid, msg.userId);
        PrintUtil.debug(tag, dbDev);
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
        for (var ob in _observers) {
          ob.onReceived(msg);
        }
      });
    }
    return this;
  }

  /// 发送消息
  bool sendMsg(History history) {
    int i = 0;
    for (var skt in _sockets) {
      MessageData msg = MessageData(App.userId, App.devInfo, history);
      String json = jsonEncode(msg);
      try {
        skt.socket.send(json.codeUnits,
            InternetAddress(Constants.multicastGroup), Constants.port);
      } catch (e, stacktrace) {
        PrintUtil.debug(tag, e);
        PrintUtil.debug(tag, stacktrace);
      }
    }
    return i > 0;
  }

  void addListener(SocketObserver observer) {
    _observers.add(observer);
  }

  void removeListener(SocketObserver observer) {
    _observers.remove(observer);
  }

  Future<List<SocketResult>> _getSockets(String multicastGroup,
      [int? port]) async {
    final interfaces = await NetworkInterface.list();
    final sockets = <SocketResult>[];
    for (final interface in interfaces) {
      try {
        final socket =
            await RawDatagramSocket.bind(InternetAddress.anyIPv4, port ?? 0);
        socket.joinMulticast(InternetAddress(multicastGroup), interface);
        sockets.add(SocketResult(interface, socket));
      } catch (e) {
        PrintUtil.debug(
          "SocketListener",
          'Could not bind UDP multicast port (ip: ${interface.addresses.map((a) => a.address).toList()}, group: $multicastGroup, port: $port)',
        );
      }
    }

    return sockets;
  }
}
