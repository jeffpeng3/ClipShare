import 'package:floor/floor.dart';

import '../entity/tables/sync_history.dart';
import '../entity/tables/user.dart';

@dao
abstract class SyncHistoryDao {
  ///根据设备 id 获取未同步记录
  @Query("")
  Future<User?> getById(String devId);

  ///添加同步记录
  @insert
  Future<int> add(SyncHistory syncHistory);

}
