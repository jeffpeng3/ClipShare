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
  order by id desc
  """)
  Future<List<OperationRecord>> getSyncRecord(int uid, String devId);

  ///删除当前用户的所有操作记录
  @Query("delete from OperationRecord where uid = :uid")
  Future<int?> removeAll(int uid);
}
