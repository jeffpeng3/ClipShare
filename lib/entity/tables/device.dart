import 'package:floor/floor.dart';

@entity
class Device {
  @PrimaryKey(autoGenerate: true)

  ///设备 id
  int? id;

  ///设备名称
  late String devName;
  late String guid;

  ///用户id（uuid）
  late String uid;

  ///设备类型
  String type = "unknown";

  ///上次链接时间
  String? lastConnTime;

  ///上次链接地址
  String? lastAddr;

  Device({
    this.id,
    required this.guid,
    required this.devName,
    required this.uid,
    required this.type,
  });
}
