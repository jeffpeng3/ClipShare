import 'package:floor/floor.dart';

import '../entity/tables/operation_sync.dart';

@dao
abstract class OperationSyncDao {
  ///添加同步记录
  @insert
  Future<int> add(OperationSync syncHistory);
}
