import 'dart:ui';

import 'package:clipshare/dao/config_dao.dart';
import 'package:clipshare/db/app_db.dart';
import 'package:clipshare/entity/settings.dart';
import 'package:clipshare/entity/tables/config.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/util/extension.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:window_manager/window_manager.dart';

final settingProvider = NotifierProvider<SettingProvider, Settings>((ref) {
  return SettingProvider();
});

class SettingProvider extends Notifier<Settings> {
  final ConfigDao _configDao = AppDb.inst.configDao;

  @override
  Settings init() {
    return App.settings;
  }

  Future<void> _addOrUpdate(String key, String value) async {
    var v = await _configDao.getConfig(key, App.userId);
    var cfg = Config(key: key, value: value, uid: App.userId);
    if (v == null) {
      await _configDao.add(cfg);
    } else {
      await _configDao.updateConfig(cfg);
    }
  }

  Future<void> setAllowDiscover(bool allowDiscover) async {
    await _addOrUpdate("allowDiscover", allowDiscover.toString());
    App.settings = state = state.copyWith(
      allowDiscover: allowDiscover,
    );
  }

  Future<void> setStartMini(bool startMini) async {
    await _addOrUpdate("startMini", startMini.toString());
    App.settings = state = state.copyWith(
      startMini: startMini,
    );
  }

  Future<void> setLaunchAtStartup(bool launchAtStartup) async {
    await _addOrUpdate("launchAtStartup", launchAtStartup.toString());
    App.settings = state = state.copyWith(
      launchAtStartup: launchAtStartup,
    );
  }

  Future<void> setPort(int port) async {
    await _addOrUpdate("port", port.toString());
    App.settings = state = state.copyWith(
      port: port,
    );
  }

  Future<void> setLocalName(String localName) async {
    await _addOrUpdate("localName", localName);
    App.devInfo.name = localName;
    App.settings = state = state.copyWith(
      localName: localName,
    );
  }

  Future<void> setShowHistoryFloat(bool showHistoryFloat) async {
    await _addOrUpdate("showHistoryFloat", showHistoryFloat.toString());
    App.settings = state = state.copyWith(
      showHistoryFloat: showHistoryFloat,
    );
  }

  Future<void> setLockHistoryFloatLoc(bool lockHistoryFloatLoc) async {
    await _addOrUpdate("lockHistoryFloatLoc", lockHistoryFloatLoc.toString());
    App.settings = state = state.copyWith(
      lockHistoryFloatLoc: lockHistoryFloatLoc,
    );
  }

  Future<void> setNotFirstStartup() async {
    await _addOrUpdate("firstStartup", false.toString());
    App.settings = state = state.copyWith(
      firstStartup: false,
    );
  }

  Future<void> setRememberWindowSize(bool rememberWindowSize) async {
    await _addOrUpdate("rememberWindowSize", rememberWindowSize.toString());
    Size size = await windowManager.getSize();
    App.settings = state = state.copyWith(
      rememberWindowSize: rememberWindowSize,
      windowSize: "${size.width}x${size.height}",
    );
  }

  Future<void> setWindowSize(Size windowSize) async {
    var size = "${windowSize.width}x${windowSize.height}";
    await _addOrUpdate("windowSize", size);
    App.settings = state = state.copyWith(
      windowSize: size,
    );
  }

  Future<void> setEnableLogsRecord(bool enableLogsRecord) async {
    await _addOrUpdate("enableLogsRecord", enableLogsRecord.toString());
    App.settings = state = state.copyWith(
      enableLogsRecord: enableLogsRecord,
    );
  }

  Future<void> setTagRegulars(String tagRegulars) async {
    await _addOrUpdate("tagRegulars", tagRegulars);
    App.settings = state = state.copyWith(
      tagRegulars: tagRegulars,
    );
  }

  Future<void> setHistoryWindowHotKeys(String historyWindowHotKeys) async {
    await _addOrUpdate("historyWindowHotKeys", historyWindowHotKeys);
    App.settings = state = state.copyWith(
      historyWindowHotKeys: historyWindowHotKeys,
    );
  }

  Future<void> setHeartbeatInterval(String heartbeatInterval) async {
    await _addOrUpdate("heartbeatInterval", heartbeatInterval);
    App.settings = state = state.copyWith(
      heartbeatInterval: heartbeatInterval.toInt(),
    );
  }
}
