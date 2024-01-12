import 'dart:convert';

import 'package:floor/floor.dart';

@entity
class Device {
  ///设备id
  @primaryKey
  late String guid;

  ///设备名称
  String devName;

  ///用户 id
  int uid;

  ///设备类型
  String type = "unknown";

  ///上次链接时间
  String? lastConnTime;

  ///上次链接地址
  String? lastAddr;

  Device({
    required this.guid,
    required this.devName,
    required this.uid,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      "guid": guid,
      "devName": devName,
      "uid": uid,
      "type": type,
      "lastConnTime": lastConnTime,
      "lastAddr": lastAddr,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  static Device fromJson(Map<String, dynamic> map) {
    return Device(
        guid: map["guid"],
        devName: map["devName"],
        uid: map["uid"],
        type: map["type"]);
  }
}
