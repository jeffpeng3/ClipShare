import 'package:floor/floor.dart';

import '../entity/tables/sync_history.dart';

@dao
abstract class SyncHistoryDao {
  ///添加同步记录
  @insert
  Future<int> add(SyncHistory syncHistory);
}
