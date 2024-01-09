import 'package:floor/floor.dart';

@entity
class OperationSync {
  ///操作记录 id
  @primaryKey
  int opId;

  ///设备 id
  @primaryKey
  String devId;

  /// 用户 id
  @primaryKey
  int uid;

  ///同步时间
  String time = DateTime.now().toString();

  OperationSync({
    required this.opId,
    required this.devId,
    required this.uid,
  });
}
