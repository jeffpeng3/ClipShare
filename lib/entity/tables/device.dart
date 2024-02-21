import 'dart:convert';

import 'package:floor/floor.dart';

import '../../db/db_util.dart';
import '../../main.dart';
import '../dev_info.dart';

@entity
class Device {
  ///设备id
  @primaryKey
  late String guid;

  ///设备名称
  String devName;

  ///用户 id
  int uid;

  ///自定义名称
  String? customName;

  ///设备类型
  String type = "unknown";

  ///上次链接时间
  String? lastConnTime;

  ///上次链接地址
  String? lastAddr;

  String get name =>
      customName == null || customName == "" ? devName : customName!;

  Device({
    required this.guid,
    required this.devName,
    required this.uid,
    required this.type,
    this.customName,
    this.lastAddr,
    this.lastConnTime,
  });

  Map<String, dynamic> toJson() {
    return {
      "guid": guid,
      "devName": devName,
      "uid": uid,
      "type": type,
      "lastConnTime": lastConnTime,
      "lastAddr": lastAddr,
      "customName": customName,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  Device.empty({
    this.guid = "",
    this.devName = "",
    this.uid = 0,
    this.type = "",
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Device &&
          runtimeType == other.runtimeType &&
          guid == other.guid &&
          uid == other.uid &&
          type == other.type;

  @override
  int get hashCode => guid.hashCode ^ uid.hashCode ^ type.hashCode;

  static Device fromJson(Map<String, dynamic> map) {
    return Device(
      guid: map["guid"],
      devName: map["devName"],
      uid: map["uid"],
      type: map["type"],
      customName: map["customName"],
    );
  }

  static Future<Device?> fromDevInfo(DevInfo dev) {
    return DBUtil.inst.deviceDao.getById(dev.guid, App.userId).then((v) => v);
  }
}
