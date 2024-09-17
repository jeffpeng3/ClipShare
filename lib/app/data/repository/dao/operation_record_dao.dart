import 'package:clipshare/app/handlers/sync/missing_data_syncer.dart';
import 'package:clipshare/app/services/socket_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:floor/floor.dart';
import 'package:get/get.dart';

import '../entity/tables/operation_record.dart';

@dao
abstract class OperationRecordDao {
  ///添加操作记录
  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<int> add(OperationRecord record);

  ///添加操作记录并发送通知设备更改
  Future<int> addAndNotify(OperationRecord record) {
    return add(record).then((cnt) {
      if (cnt == 0) return cnt;
      final sktService = Get.find<SocketService>();
      //发送变更至已连接的所有设备
      MissingDataSyncer.process(record).then((shouldRemove) {
        sktService.sendData(null, MsgType.sync, record.toJson());
      });
      return cnt;
    });
  }

  ///获取某用户某设备的未同步记录
  @Query("""
  select * from OperationRecord record
  where not exists (
    select 1 from OperationSync opsync
    where opsync.uid = :uid and opsync.devId = :toDevId and opsync.opId = record.id
  ) and devId in (:fromDevIds)
  order by id desc
  """)
  Future<List<OperationRecord>> getSyncRecord(
    int uid,
    String toDevId,
    List<String> fromDevIds,
  );

  ///删除当前用户的所有操作记录
  @Query("delete from OperationRecord where uid = :uid")
  Future<int?> removeAll(int uid);

  ///根据 id 删除记录
  @Query("delete from OperationRecord where id in (:ids)")
  Future<int?> deleteByIds(List<int> ids);

  @Query(
    "select * from OperationRecord where uid = :uid and module = :module and method = :opMethod and data = :id",
  )
  Future<OperationRecord?> getByDataId(
    int id,
    String module,
    String opMethod,
    int uid,
  );

  /// 删除指定模块的同步记录
  @Query(
    "delete from OperationRecord where uid = :uid and module = :module",
  )
  Future<int?> removeByModule(String module, int uid);

  /// 删除指定模块的同步记录(Android 不支持 json_extract)
  @Query(
    r"delete from OperationRecord where uid = :uid and module = '规则设置' and substr(data,instr(data,':') + 2,instr(data,',') - 3 - instr(data,':')) = :rule",
  )
  Future<int?> removeRuleRecord(String rule, int uid);
}
