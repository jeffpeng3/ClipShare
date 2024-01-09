import 'package:clipshare/dao/config_dao.dart';
import 'package:clipshare/dao/device_dao.dart';
import 'package:clipshare/dao/history_dao.dart';
import 'package:clipshare/dao/user_dao.dart';
import 'package:floor/floor.dart';

import '../dao/history_tag_dao.dart';
import '../dao/operation_record_dao.dart';
import '../dao/operation_sync_dao.dart';
import 'app_db.dart';

class DBUtil {
  //单例
  static DBUtil? _singleton;

  ///定义数据库变量
  late final AppDb _db;

  ///私有化构造函数
  DBUtil._private();

  bool _inited = false;
  bool _initing = false;

  static DBUtil get inst => _singleton ??= DBUtil._private();

  void dispose() => _singleton = null;

  Future<AppDb?> init() {
    if (!_inited && !_initing) {
      _initing = true;
      return $FloorAppDb.databaseBuilder('clipshare.db').build().then((value) {
        _db = value;
        _inited = true;
        _initing = false;
        return Future.value(_db);
      });
    }
    return Future.value();
  }

  ConfigDao get configDao => _db.configDao;

  HistoryDao get historyDao => _db.historyDao;

  DeviceDao get deviceDao => _db.deviceDao;

  UserDao get userDao => _db.userDao;

  OperationSyncDao get operationSyncDao => _db.operationSyncDao;

  HistoryTagDao get historyTagDao => _db.historyTagDao;

  OperationRecordDao get opRecordDao => _db.operationRecordDao;

  //迁移策略,数据库版本1->2
  final migration1to2 = Migration(1, 2, (database) async {
    // await database.execute('ALTER TABLE PhoneBean ADD COLUMN os INTEGER');
  });
}
