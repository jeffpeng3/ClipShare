import 'package:clipshare/dao/config_dao.dart';
import 'package:clipshare/db/db_util.dart';
import 'package:clipshare/entity/settings.dart';
import 'package:clipshare/entity/tables/config.dart';
import 'package:clipshare/main.dart';
import 'package:refena_flutter/refena_flutter.dart';

final settingProvider = NotifierProvider<SettingProvider, Settings>((ref) {
  return SettingProvider();
});

class SettingProvider extends Notifier<Settings> {
  final ConfigDao _configDao = DBUtil.inst.configDao;

  @override
  Settings init() {
    var settings = App.settings;
    return Settings(
      port: settings.port,
      localName: settings.localName,
      launchAtStartup: settings.launchAtStartup,
      startMini: settings.startMini,
      allowDiscover: settings.allowDiscover,
      showHistoryFloat: settings.showHistoryFloat,
      firstStartup: settings.firstStartup,
    );
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
    state = state.copyWith(
      allowDiscover: allowDiscover,
    );
  }

  Future<void> setStartMini(bool startMini) async {
    await _addOrUpdate("startMini", startMini.toString());
    state = state.copyWith(
      startMini: startMini,
    );
  }

  Future<void> setLaunchAtStartup(bool launchAtStartup) async {
    await _addOrUpdate("launchAtStartup", launchAtStartup.toString());
    state = state.copyWith(
      launchAtStartup: launchAtStartup,
    );
  }

  Future<void> setPort(int port) async {
    await _addOrUpdate("port", port.toString());
    state = state.copyWith(
      port: port,
    );
  }

  Future<void> setLocalName(String localName) async {
    await _addOrUpdate("localName", localName);
    App.devInfo.name = localName;
    state = state.copyWith(
      localName: localName,
    );
  }

  Future<void> setShowHistoryFloat(bool showHistoryFloat) async {
    await _addOrUpdate("showHistoryFloat", showHistoryFloat.toString());
    state = state.copyWith(
      showHistoryFloat: showHistoryFloat,
    );
  }

  Future<void> setFirstStartup() async {
    await _addOrUpdate("firstStartup", false.toString());
    state = state.copyWith(
      showHistoryFloat: false,
    );
  }
}
