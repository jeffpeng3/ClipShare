// 必须的包
import 'dart:async';

import 'package:clipshare/dao/config_dao.dart';
import 'package:clipshare/dao/device_dao.dart';
import 'package:clipshare/dao/history_dao.dart';
import 'package:clipshare/dao/user_dao.dart';
import 'package:clipshare/entity/tables/history_tag.dart';
import 'package:clipshare/entity/tables/operation_sync.dart';
import 'package:clipshare/entity/views/v_history_tag_hold.dart';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../dao/history_tag_dao.dart';
import '../dao/operation_record_dao.dart';
import '../dao/operation_sync_dao.dart';
import '../entity/tables/config.dart';
import '../entity/tables/device.dart';
import '../entity/tables/history.dart';
import '../entity/tables/operation_record.dart';
import '../entity/tables/user.dart';

part 'app_db.floor.g.dart';

/// 添加实体类到 @Database 注解中，app_db、db_util 中添加 get 方法
/// 生成方法（二选一）
///
/// 1. 执行命令 flutter pub run build_runner build --delete-conflicting-outputs
///    生成的文件位于 .dart_tool/build/generated/项目名称/lib/db
///    下面这行放在 app_db.floor.g.dart 文件里，使其变成 app_database.dart 文件的一部分
///    part of 'app_db.dart';
///
/// 2. 直接执行 /scripts/db_gen.bat 一键完成
@Database(
  version: 1,
  entities: [
    Config,
    Device,
    History,
    User,
    OperationSync,
    HistoryTag,
    OperationRecord,
  ],
  views: [
    VHistoryTagHold,
  ],
)
abstract class _AppDb extends FloorDatabase {
  UserDao get userDao;

  ConfigDao get configDao;

  HistoryDao get historyDao;

  DeviceDao get deviceDao;

  OperationSyncDao get operationSyncDao;

  HistoryTagDao get historyTagDao;

  OperationRecordDao get operationRecordDao;
}

class AppDb {
  static const tag = "AppDb";

  //单例
  static AppDb? _singleton;

  ///定义数据库变量
  late final _AppDb _db;

  ///私有化构造函数
  AppDb._private();

  bool _inited = false;
  bool _initing = false;

  static AppDb get inst => _singleton ??= AppDb._private();

  sqflite.DatabaseExecutor get dbExecutor => _db.database;

  void dispose() => _singleton = null;

  Future<bool> init() {
    if (_inited) {
      throw Exception("The initialization has been completed");
    }
    if (_initing) {
      throw Exception("Initializing in progress");
    }
    _initing = true;
    return $FloorAppDb.databaseBuilder('clipshare.db').build().then((value) {
      _db = value;
      _inited = true;
      _initing = false;
      return Future.value(true);
    });
  }

  Future<void> close(){
    return _db.close();
  }

  ConfigDao get configDao => _db.configDao;

  HistoryDao get historyDao => _db.historyDao;

  DeviceDao get deviceDao => _db.deviceDao;

  UserDao get userDao => _db.userDao;

  OperationSyncDao get opSyncDao => _db.operationSyncDao;

  HistoryTagDao get historyTagDao => _db.historyTagDao;

  OperationRecordDao get opRecordDao => _db.operationRecordDao;

//迁移策略,数据库版本1->2
// final migration1to2 = Migration(1, 2, (database) async {
//   // await database.execute('ALTER TABLE PhoneBean ADD COLUMN os INTEGER');
// });
}
