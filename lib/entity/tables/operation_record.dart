import 'dart:convert';

import 'package:clipshare/main.dart';
import 'package:floor/floor.dart';

import '../../util/constants.dart';

///
/// 操作记录表
@Entity(indices: [
  Index(value: ['uid', "module", "method"])
])
class OperationRecord {
  ///主键 id
  @PrimaryKey(autoGenerate: true)
  late int id;

  ///用户 id
  late int uid;

  ///操作模块
  @TypeConverters([ModuleTypeConverter])
  late Module module;

  /// 操作方法
  @TypeConverters([OpMethodTypeConverter])
  late OpMethod method;

  /// 操作数据，如果是json表示是整个数据，否则表示是主键
  late String data;

  /// 操作时间
  String time = DateTime.now().toString();

  OperationRecord({
    required this.id,
    required this.uid,
    required this.module,
    required this.method,
    required this.data,
  });

  OperationRecord.fromSimple(this.module, this.method, Object data) {
    id = App.snowflake.nextId();
    uid = App.userId;
    this.data = data.toString();
  }

  static OperationRecord fromJson(map) {
    var id = map["id"];
    var uid = map["uid"];
    var module = Module.getValue(map["module"]);
    var method = OpMethod.getValue(map["method"]);
    var data = map["data"];
    var time = map["time"];
    var record = OperationRecord(
      id: id,
      uid: uid,
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
      "module": module.moduleName,
      "method": method.name,
      "data": data,
      "time": time,
    };
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
