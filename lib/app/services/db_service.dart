import 'dart:async';
import 'dart:io';

import 'package:clipshare/app/data/repository/dao/config_dao.dart';
import 'package:clipshare/app/data/repository/dao/device_dao.dart';
import 'package:clipshare/app/data/repository/dao/history_dao.dart';
import 'package:clipshare/app/data/repository/dao/history_tag_dao.dart';
import 'package:clipshare/app/data/repository/dao/operation_record_dao.dart';
import 'package:clipshare/app/data/repository/dao/operation_sync_dao.dart';
import 'package:clipshare/app/data/repository/dao/user_dao.dart';
import 'package:clipshare/app/data/repository/entity/tables/config.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/data/repository/entity/tables/history_tag.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_sync.dart';
import 'package:clipshare/app/data/repository/entity/tables/user.dart';
import 'package:clipshare/app/data/repository/entity/views/v_history_tag_hold.dart';
import 'package:floor/floor.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

part 'package:clipshare/app/data/repository/db/app_db.floor.g.dart';

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
  version: 2,
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

class DbService extends GetxService {
  ///定义数据库变量
  late final _AppDb _db;

  ConfigDao get configDao => _db.configDao;

  HistoryDao get historyDao => _db.historyDao;

  DeviceDao get deviceDao => _db.deviceDao;

  UserDao get userDao => _db.userDao;

  OperationSyncDao get opSyncDao => _db.operationSyncDao;

  HistoryTagDao get historyTagDao => _db.historyTagDao;

  OperationRecordDao get opRecordDao => _db.operationRecordDao;
  final tag = "DbService";

  sqflite.DatabaseExecutor get dbExecutor => _db.database;
  Future _queue = Future.value();

  void execSequentially(Future Function() f) {
    _queue = _queue.whenComplete(() => f());
  }

  Future<DbService> init() async {
    // 获取应用程序的文件目录
    String databasesPath = "clipshare.db";
    if (Platform.isWindows) {
      var dirPath = Directory(Platform.resolvedExecutable).parent.path;
      databasesPath = "$dirPath\\$databasesPath";
    }
    _db = await $Floor_AppDb
        .databaseBuilder(databasesPath)
        .addMigrations([migration1to2]).build();
    return this;
  }

  Future<void> close() {
    return _db.close();
  }

  ///----- 迁移策略 更新数据库版本后需要重新生成数据库代码 -----
  ///数据库版本 1 -> 2
  ///操作记录表新增设备id字段，用于从连接设备同步其他已配对设备数据
  final migration1to2 = Migration(1, 2, (database) async {
    await database.execute('ALTER TABLE OperationRecord ADD COLUMN devId TEXT');
    // await database
    //     .execute("UPDATE OperationRecord SET devId = '${App.device.guid}'");
  });
}
