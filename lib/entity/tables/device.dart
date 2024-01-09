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
}
