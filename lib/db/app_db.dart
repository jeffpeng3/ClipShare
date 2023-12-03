// 必须的包
import 'dart:async';
import 'package:floor/floor.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../dao/user_dao.dart';
import '../dao/config_dao.dart';
import '../dao/history_dao.dart';
import '../dao/device_dao.dart';
import '../entity/tables/config.dart';
import '../entity/tables/device.dart';
import '../entity/tables/history.dart';
import '../entity/tables/user.dart';

part 'app_db.floor.g.dart';

/// 执行命令 flutter pub run build_runner build --delete-conflicting-outputs
///
/// 下面这行放在app_db.g.dart文件里，使其变成app_database.dart文件的一部分
/// part of 'app_db.dart';
@Database(version: 1, entities: [Config, Device, History, User])
abstract class AppDb extends FloorDatabase {
  UserDao get userDao;

  ConfigDao get configDao;

  HistoryDao get historyDao;

  DeviceDao get deviceDao;
}
