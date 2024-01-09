import 'package:floor/floor.dart';

import '../entity/tables/operation_record.dart';

@dao
abstract class OperationRecordDao {
  ///添加操作记录
  @insert
  Future<int> add(OperationRecord record);
}
