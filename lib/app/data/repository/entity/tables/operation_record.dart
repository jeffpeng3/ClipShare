import 'dart:convert';

import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:floor/floor.dart';
import 'package:get/get.dart';

///
/// 操作记录表
@Entity(
  indices: [
    Index(value: ['uid', "module", "method"]),
  ],
)
class OperationRecord {
  ///主键 id
  @primaryKey
  late int id;

  ///用户 id
  late int uid;

  ///记录来自哪台设备
  late String devId;

  ///操作模块
  @TypeConverters([ModuleTypeConverter])
  late Module module;

  /// 操作方法
  @TypeConverters([OpMethodTypeConverter])
  late OpMethod method;

  /// history的主键
  late String data;

  /// 操作时间
  String time = DateTime.now().toString();

  OperationRecord({
    required this.id,
    required this.uid,
    required this.devId,
    required this.module,
    required this.method,
    required this.data,
  });

  OperationRecord.fromSimple(this.module, this.method, Object data) {
    final appConfig = Get.find<ConfigService>();
    id = appConfig.snowflake.nextId();
    uid = appConfig.userId;
    devId = appConfig.device.guid;
    this.data = data.toString();
  }

  static OperationRecord fromJson(map) {
    var id = map["id"];
    var uid = map["uid"];
    var module = Module.getValue((map["module"]));
    var method = OpMethod.getValue(map["method"]);
    var data = map["data"];
    var time = map["time"];
    var devId = map["devId"];
    var record = OperationRecord(
      id: id,
      uid: uid,
      devId: devId,
      module: module,
      method: method,
      data: data,
    );
    record.time = time;
    return record;
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "uid": uid,
      "devId": devId,
      "module": module.moduleName,
      "method": method.name,
      "data": data,
      "time": time,
    };
  }

  OperationRecord copyWith(String data) {
    return fromJson(toJson())..data = data;
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

// 枚举类型到String的转换器
class OpMethodTypeConverter extends TypeConverter<OpMethod, String> {
  @override
  OpMethod decode(String name) {
    return OpMethod.getValue(name);
  }

  @override
  String encode(OpMethod value) {
    return value.name;
  }
}

// 枚举类型到String的转换器
class ModuleTypeConverter extends TypeConverter<Module, String> {
  @override
  Module decode(String name) {
    return Module.getValue(name);
  }

  @override
  String encode(Module value) {
    return value.moduleName;
  }
}
