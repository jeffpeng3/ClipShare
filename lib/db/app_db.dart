// 必须的包
import 'dart:async';

import 'package:clipshare/dao/sync_history_dao.dart';
import 'package:clipshare/entity/tables/history_tag.dart';
import 'package:clipshare/entity/tables/sync_history.dart';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../dao/config_dao.dart';
import '../dao/device_dao.dart';
import '../dao/history_dao.dart';
import '../dao/user_dao.dart';
import '../entity/tables/config.dart';
import '../entity/tables/device.dart';
import '../entity/tables/history.dart';
import '../entity/tables/user.dart';

part 'app_db.floor.g.dart';

/// 执行命令 flutter pub run build_runner build --delete-conflicting-outputs
/// 生成的文件位于 .dart_tool/build/generated/项目名称/lib/db
/// 下面这行放在 app_db.floor.g.dart 文件里，使其变成 app_database.dart 文件的一部分
/// part of 'app_db.dart';
@Database(version: 1, entities: [Config, Device, History, User,SyncHistory,HistoryTag])
abstract class AppDb extends FloorDatabase {
  UserDao get userDao;

  ConfigDao get configDao;

  HistoryDao get historyDao;

  DeviceDao get deviceDao;

  SyncHistoryDao get syncHistoryDao;
}
