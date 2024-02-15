import 'package:floor/floor.dart';

import '../entity/tables/operation_sync.dart';

@dao
abstract class OperationSyncDao {
  ///添加同步记录
  @insert
  Future<int> add(OperationSync syncHistory);

  ///删除当前用户的所有操作同步记录
  @Query("delete OperationSync where uid = :uid")
  Future<int?> removeAll(int uid);
}
