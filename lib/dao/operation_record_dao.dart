import 'package:clipshare/handler/sync/missing_data_syncer.dart';
import 'package:clipshare/listeners/socket_listener.dart';
import 'package:clipshare/util/constants.dart';
import 'package:floor/floor.dart';

import '../entity/tables/operation_record.dart';

@dao
abstract class OperationRecordDao {
  ///添加操作记录
  @insert
  Future<int> add(OperationRecord record);

  ///添加操作记录并发送通知设备更改
  Future<int> addAndNotify(OperationRecord record) {
    return add(record).then((cnt) {
      if (cnt == 0) return cnt;
      //发送变更至已连接的所有设备
      MissingDataSyncer.process(record, []).then((v) {
        SocketListener.inst.sendData(null, MsgType.sync, record.toJson());
      });
      return cnt;
    });
  }

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
}
