import 'package:floor/floor.dart';

import '../entity/tables/operation_record.dart';

@dao
abstract class OperationRecordDao {
  ///添加操作记录
  @insert
  Future<int> add(OperationRecord record);

  ///获取某用户某设备的未同步记录
  @Query("""
  select * from OperationRecord record
  where not exists (
    select 1 from OperationSync opsync
    where opsync.uid = :uid and opsync.devId = :devId and opsync.opId = record.id
  )
  """)
  Future<List<OperationRecord>> getSyncRecord(int uid, String devId);
}
