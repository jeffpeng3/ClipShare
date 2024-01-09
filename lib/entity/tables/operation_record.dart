import 'dart:convert';

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
  int id;

  ///用户 id
  int uid;

  ///操作模块
  String module;

  /// 操作方法
  @TypeConverters([OpMethodTypeConverter])
  OpMethod method;

  /// 操作数据，如果是json表示是整个数据，否则表示是主键
  String data;

  /// 操作时间
  String time = DateTime.now().toString();

  OperationRecord({
    required this.id,
    required this.uid,
    required this.module,
    required this.method,
    required this.data,
  });

  static OperationRecord fromJson(map) {
    var id = map["id"];
    var uid = map["uid"];
    var module = map["module"];
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
      "module": module,
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
