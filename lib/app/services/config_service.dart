import 'dart:async';
import 'dart:io';

import 'package:clipboard_listener/enums.dart';
import 'package:clipshare/app/data/repository/entity/dev_info.dart';
import 'package:clipshare/app/data/repository/entity/tables/config.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/data/repository/entity/version.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/crypto.dart';
import 'package:clipshare/app/utils/extension.dart';
import 'package:clipshare/app/utils/snowflake.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_handler/share_handler.dart';
import 'package:window_manager/window_manager.dart';

class ConfigService extends GetxService {
  final dbService = Get.find<DbService>();

  //region 属性

  //region 常量
  //通用通道
  final commonChannel = const MethodChannel(Constants.channelCommon);

  //剪贴板通道
  final clipChannel = const MethodChannel(Constants.channelClip);

  //Android平台通道
  final androidChannel = const MethodChannel(Constants.channelAndroid);
  final prime1 = CryptoUtil.getPrime();
  final prime2 = CryptoUtil.getPrime();
  final bgColor = const Color.fromARGB(255, 238, 238, 238);
  WindowController? compactWindow;
  WindowController? onlineDevicesWindow;
  final mainWindowId = 0;

  StreamSubscription<SharedMedia>? shareHandlerStream;

  //当前设备id
  late final DevInfo devInfo;
  late final Device device;
  late final Snowflake snowflake;
  late final Version version;
  late final double osVersion;
  final minVersion = const Version("1.0.0-beta", "3");

  //路径
  late final String documentPath;
  late final String androidPrivatePicturesPath;
  late final String cachePath;

  //文件默认存储路径
  String get defaultFileStorePath {
    var path = "${Directory(Platform.resolvedExecutable).parent.path}/files";
    if (Platform.isAndroid) {
      path = "${Constants.androidDownloadPath}/${Constants.appName}";
    }
    var dir = Directory(path);
    if (!dir.existsSync()) {
      dir.createSync();
    }
    return Directory(path).normalizePath;
  }

  //日志路径
  String get logsDirPath {
    var path = "$cachePath/logs";
    if (Platform.isWindows) {
      path = Directory(
        "${Directory(Platform.resolvedExecutable).parent.path}/logs",
      ).absolute.normalizePath;
    }
    var dir = Directory(path);
    if (!dir.existsSync()) {
      dir.createSync();
    }
    return Directory(path).normalizePath;
  }

  //endregion

  //region 响应式

  //region 应用内配置
  bool get isSmallScreen => Get.width <= Constants.smallScreenWidth;
  final isHistorySyncing = false.obs;

  final _innerCopy = false.obs;

  bool get innerCopy => _innerCopy.value;

  set innerCopy(bool value) {
    _innerCopy.value = value;
    Future.delayed(const Duration(milliseconds: 300), () {
      _innerCopy.value = false;
    });
  }

  final _isMultiSelectionMode = false.obs;
  GetxController? _selectionModeController;
  final _multiSelectionText = "多选操作".obs;

  bool isMultiSelectionMode(GetxController controller) {
    if (controller == _selectionModeController && _isMultiSelectionMode.value) {
      return true;
    }
    return false;
  }

  String get multiSelectionText => _multiSelectionText.value;

  set multiSelectionText(val) => _multiSelectionText.value = val;

  void enableMultiSelectionMode({
    String? selectionTips,
    required GetxController controller,
  }) {
    _isMultiSelectionMode.value = true;
    _selectionModeController = controller;
    if (selectionTips != null) {
      _multiSelectionText.value = selectionTips;
    }
  }

  void disableMultiSelectionMode([bool clear = true]) {
    _isMultiSelectionMode.value = false;
    if (clear) {
      _selectionModeController = null;
    }
  }

  final authenticating = false.obs;

  final _userId = 0.obs;

  set userId(value) => _userId.value = value;

  int get userId => _userId.value;

  //endregion

  //region 存储于数据库的配置
  //端口
  late final RxInt _port;

  int get port => _port.value;

  //本地名称（设备名称）
  late final RxString _localName;

  String get localName => _localName.value;

  //开机启动
  late final RxBool _launchAtStartup;

  bool get launchAtStartup => _launchAtStartup.value;

  //启动最小化
  late final RxBool _startMini;

  bool get startMini => _startMini.value;

  //允许自动发现
  late final RxBool _allowDiscover;

  bool get allowDiscover => _allowDiscover.value;

  //显示历史悬浮窗
  late final RxBool _showHistoryFloat;

  bool get showHistoryFloat => _showHistoryFloat.value;

  //锁定悬浮窗位置
  late final RxBool _lockHistoryFloatLoc;

  bool get lockHistoryFloatLoc => _lockHistoryFloatLoc.value;

  //是否第一次打开软件
  late final RxBool _firstStartup;

  bool get firstStartup => _firstStartup.value;

  //记录的上次窗口大小，格式为：width x height。默认值为：1000x650
  late final RxString _windowSize;

  String get windowSize => _windowSize.value;

  //是否记住窗体大小
  late final RxBool _rememberWindowSize;

  bool get rememberWindowSize => _rememberWindowSize.value;

  //标签规则
  late final RxString _tagRules;

  String get tagRules => _tagRules.value;

  //短信规则
  late final RxString _smsRules;

  String get smsRules => _smsRules.value;

  //启用日志记录
  late final RxBool _enableLogsRecord;

  bool get enableLogsRecord => _enableLogsRecord.value;

  //历史记录弹窗快捷键
  late final RxString _historyWindowHotKeys;

  String get historyWindowHotKeys => _historyWindowHotKeys.value;

  //文件同步快捷键
  late final RxString _syncFileHotKeys;

  String get syncFileHotKeys => _syncFileHotKeys.value;

  //心跳间隔时长
  late final RxInt _heartbeatInterval;

  int get heartbeatInterval => _heartbeatInterval.value;

  //文件存储路径
  late final RxString _fileStorePath;

  String get fileStorePath => _fileStorePath.value;

  //保存至相册
  late final RxBool _saveToPictures;

  bool get saveToPictures => _saveToPictures.value;

  //忽略Shizuku权限
  late final RxBool _ignoreShizuku;

  bool get ignoreShizuku => _ignoreShizuku.value;

  //使用安全认证
  late final RxBool _useAuthentication;

  bool get useAuthentication => _useAuthentication.value;

  //app密码重新验证时长
  late final RxInt _appRevalidateDuration;

  int get appRevalidateDuration => _appRevalidateDuration.value;

  //app密码
  late final Rx<String?> _appPassword;

  String? get appPassword => _appPassword.value;

  //是否启用短信同步
  late final RxBool _enableSmsSync;

  bool get enableSmsSync => _enableSmsSync.value;

  //是否启用短信同步
  late final RxBool _enableForward;

  bool get enableForward => _enableForward.value;

  //中转服务器地址
  late final Rx<String?> _forwardServer;

  String? get forwardServer => _forwardServer.value;

  //选择的工作模式（Android）
  late final Rx<EnvironmentType?> _workingMode;

  EnvironmentType? get workingMode => _workingMode.value;

  //endregion

  //endregion

  //endregion

  //region 初始化

  Future<ConfigService> init() async {
    await initDeviceInfo();
    snowflake = Snowflake(device.guid.hashCode);
    await loadConfigs();
    await initPath();
    return this;
  }

  ///加载配置信息
  Future<void> loadConfigs() async {
    var cfg = dbService.configDao;
    var port = await cfg.getConfig(
      "port",
      userId,
    );
    var localName = await cfg.getConfig(
      "localName",
      userId,
    );
    var startMini = await cfg.getConfig(
      "startMini",
      userId,
    );
    var launchAtStartup = await cfg.getConfig(
      "launchAtStartup",
      userId,
    );
    var allowDiscover = await cfg.getConfig(
      "allowDiscover",
      userId,
    );
    var showHistoryFloat = await cfg.getConfig(
      "showHistoryFloat",
      userId,
    );
    var firstStartup = await cfg.getConfig(
      "firstStartup",
      userId,
    );
    var windowSize = await cfg.getConfig(
      "windowSize",
      userId,
    );
    var rememberWindowSize = await cfg.getConfig(
      "rememberWindowSize",
      userId,
    );
    var lockHistoryFloatLoc = await cfg.getConfig(
      "lockHistoryFloatLoc",
      userId,
    );
    var enableLogsRecord = await cfg.getConfig(
      "enableLogsRecord",
      userId,
    );
    var tagRules = await cfg.getConfig(
      "tagRules",
      userId,
    );
    var smsRules = await cfg.getConfig(
      "smsRules",
      userId,
    );
    var historyWindowHotKeys = await cfg.getConfig(
      "historyWindowHotKeys",
      userId,
    );
    var syncFileHotKeys = await cfg.getConfig(
      "syncFileHotKeys",
      userId,
    );
    var heartbeatInterval = await cfg.getConfig(
      "heartbeatInterval",
      userId,
    );
    var fileStorePath = await cfg.getConfig(
      "fileStorePath",
      userId,
    );
    var saveToPictures = await cfg.getConfig(
      "saveToPictures",
      userId,
    );
    var ignoreShizuku = await cfg.getConfig(
      "ignoreShizuku",
      userId,
    );
    var useAuthentication = await cfg.getConfig(
      "useAuthentication",
      userId,
    );
    var appRevalidateDuration = await cfg.getConfig(
      "appRevalidateDuration",
      userId,
    );
    var appPassword = await cfg.getConfig(
      "appPassword",
      userId,
    );
    var enableSmsSync = await cfg.getConfig(
      "enableSmsSync",
      userId,
    );
    var enableForward = await cfg.getConfig(
      "enableForward",
      userId,
    );
    var forwardServer = await cfg.getConfig(
      "forwardServer",
      userId,
    );
    var workingMode = await cfg.getConfig(
          "workingMode",
          userId,
        ) ??
        "none";
    var fileStoreDir = Directory(fileStorePath ?? defaultFileStorePath);
    _port = port?.toInt().obs ?? Constants.port.obs;
    _localName =
        localName.isNotNullAndEmpty ? localName!.obs : devInfo.name.obs;
    _startMini = startMini?.toBool().obs ?? false.obs;
    _launchAtStartup = launchAtStartup?.toBool().obs ?? false.obs;
    _allowDiscover = allowDiscover?.toBool().obs ?? true.obs;
    _showHistoryFloat = showHistoryFloat?.toBool().obs ?? false.obs;
    _firstStartup = firstStartup?.toBool().obs ?? true.obs;
    _windowSize =
        windowSize.isNullOrEmpty || rememberWindowSize?.toBool() != true
            ? Constants.defaultWindowSize.obs
            : windowSize!.obs;
    _rememberWindowSize = rememberWindowSize?.toBool().obs ?? false.obs;
    _lockHistoryFloatLoc = lockHistoryFloatLoc?.toBool().obs ?? true.obs;
    _enableLogsRecord = enableLogsRecord?.toBool().obs ?? false.obs;
    _tagRules = tagRules?.obs ?? Constants.defaultTagRules.obs;
    _smsRules = smsRules?.obs ?? Constants.defaultSmsRules.obs;
    _historyWindowHotKeys =
        historyWindowHotKeys?.obs ?? Constants.defaultHistoryWindowKeys.obs;
    _syncFileHotKeys =
        syncFileHotKeys?.obs ?? Constants.defaultSyncFileHotKeys.obs;
    _heartbeatInterval =
        heartbeatInterval?.toInt().obs ?? Constants.heartbeatInterval.obs;
    _fileStorePath = fileStoreDir.absolute.normalizePath.obs;
    _saveToPictures = saveToPictures?.toBool().obs ?? false.obs;
    _ignoreShizuku = ignoreShizuku?.toBool().obs ?? false.obs;
    _useAuthentication = useAuthentication?.toBool().obs ?? false.obs;
    _appRevalidateDuration = appRevalidateDuration?.toInt().obs ?? 0.obs;
    _appPassword = appPassword.obs;
    _enableSmsSync = enableSmsSync?.toBool().obs ?? false.obs;
    _enableForward = enableForward?.toBool().obs ?? false.obs;
    _forwardServer = forwardServer.obs;
    devInfo.name = _localName.value;
    _workingMode = EnvironmentType.parse(workingMode).obs;
  }

  ///初始化路径信息
  Future<void> initPath() async {
    if (Platform.isAndroid) {
      // /storage/emulated/0/Android/data/top.coclyun.clipshare/files/documents
      documentPath = (await getExternalStorageDirectories(
        type: StorageDirectory.documents,
      ))![0]
          .path;
      androidPrivatePicturesPath = (await getExternalStorageDirectories(
        type: StorageDirectory.pictures,
      ))![0]
          .path;
      // /storage/emulated/0/Android/data/top.coclyun.clipshare/cache
      cachePath = (await getExternalCacheDirectories())![0].path;
    } else {
      documentPath = (await getApplicationDocumentsDirectory()).path;
      cachePath = (await getApplicationCacheDirectory()).path;
    }
  }

  ///初始化设备信息
  Future<void> initDeviceInfo() async {
    //读取版本信息
    var pkgInfo = await PackageInfo.fromPlatform();
    version = Version(pkgInfo.version, pkgInfo.buildNumber);
    //读取设备id信息
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      var androidInfo = await deviceInfo.androidInfo;
      var guid = CryptoUtil.toMD5(androidInfo.id);
      var name = androidInfo.model;
      var type = "Android";
      devInfo = DevInfo(guid, name, type);
      device = Device(
        guid: guid,
        devName: "本机",
        uid: 0,
        type: type,
      );
      var release = androidInfo.version.release;
      osVersion = RegExp(r"\d+").firstMatch(release)!.group(0)!.toDouble();
    } else if (Platform.isWindows) {
      var windowsInfo = await deviceInfo.windowsInfo;
      var guid = CryptoUtil.toMD5(windowsInfo.deviceId);
      var name = windowsInfo.computerName;
      var type = "Windows";
      devInfo = DevInfo(guid, name, type);
      device = Device(
        guid: guid,
        devName: "本机",
        uid: userId,
        type: type,
      );
    } else {
      throw Exception("Not Support Platform");
    }
  }

//endregion

  //region 更新存储于数据库的配置
  Future<void> _addOrUpdateDbConfig(String key, String value) async {
    var v = await dbService.configDao.getConfig(key, userId);
    var cfg = Config(key: key, value: value, uid: userId);
    if (v == null) {
      await dbService.configDao.add(cfg);
    } else {
      await dbService.configDao.updateConfig(cfg);
    }
  }

  Future<void> setAllowDiscover(bool allowDiscover) async {
    await _addOrUpdateDbConfig("allowDiscover", allowDiscover.toString());
    _allowDiscover.value = allowDiscover;
  }

  Future<void> setStartMini(bool startMini) async {
    await _addOrUpdateDbConfig("startMini", startMini.toString());
    _startMini.value = startMini;
  }

  Future<void> setLaunchAtStartup(bool launchAtStartup) async {
    await _addOrUpdateDbConfig("launchAtStartup", launchAtStartup.toString());
    _launchAtStartup.value = launchAtStartup;
  }

  Future<void> setPort(int port) async {
    await _addOrUpdateDbConfig("port", port.toString());
    _port.value = port;
  }

  Future<void> setLocalName(String localName) async {
    await _addOrUpdateDbConfig("localName", localName);
    devInfo.name = localName;
    _localName.value = localName;
  }

  Future<void> setShowHistoryFloat(bool showHistoryFloat) async {
    await _addOrUpdateDbConfig("showHistoryFloat", showHistoryFloat.toString());
    _showHistoryFloat.value = showHistoryFloat;
  }

  Future<void> setLockHistoryFloatLoc(bool lockHistoryFloatLoc) async {
    await _addOrUpdateDbConfig(
        "lockHistoryFloatLoc", lockHistoryFloatLoc.toString());
    _lockHistoryFloatLoc.value = lockHistoryFloatLoc;
  }

  Future<void> setNotFirstStartup() async {
    await _addOrUpdateDbConfig("firstStartup", false.toString());
    _firstStartup.value = firstStartup;
  }

  Future<void> setRememberWindowSize(bool rememberWindowSize) async {
    await _addOrUpdateDbConfig(
        "rememberWindowSize", rememberWindowSize.toString());
    Size size = await windowManager.getSize();
    _rememberWindowSize.value = rememberWindowSize;
    _windowSize.value = "${size.width}x${size.height}";
  }

  Future<void> setWindowSize(Size windowSize) async {
    var size = "${windowSize.width}x${windowSize.height}";
    await _addOrUpdateDbConfig("windowSize", size);
    _windowSize.value = size;
  }

  Future<void> setEnableLogsRecord(bool enableLogsRecord) async {
    await _addOrUpdateDbConfig("enableLogsRecord", enableLogsRecord.toString());
    _enableLogsRecord.value = enableLogsRecord;
  }

  Future<void> setTagRules(String tagRules) async {
    await _addOrUpdateDbConfig("tagRules", tagRules);
    _tagRules.value = tagRules;
  }

  Future<void> setSmsRules(String smsRules) async {
    await _addOrUpdateDbConfig("smsRules", smsRules);
    _smsRules.value = smsRules;
  }

  Future<void> setHistoryWindowHotKeys(String historyWindowHotKeys) async {
    await _addOrUpdateDbConfig("historyWindowHotKeys", historyWindowHotKeys);
    _historyWindowHotKeys.value = historyWindowHotKeys;
  }

  Future<void> setSyncFileHotKeys(String syncFileHotKeys) async {
    await _addOrUpdateDbConfig("syncFileHotKeys", syncFileHotKeys);
    _syncFileHotKeys.value = syncFileHotKeys;
  }

  Future<void> setHeartbeatInterval(String heartbeatInterval) async {
    await _addOrUpdateDbConfig("heartbeatInterval", heartbeatInterval);
    _heartbeatInterval.value = heartbeatInterval.toInt();
  }

  Future<void> setFileStorePath(String fileStorePath) async {
    await _addOrUpdateDbConfig("fileStorePath", fileStorePath);
    _fileStorePath.value = fileStorePath;
  }

  Future<void> setSaveToPictures(bool saveToPictures) async {
    await _addOrUpdateDbConfig("saveToPictures", saveToPictures.toString());
    _saveToPictures.value = saveToPictures;
  }

  Future<void> setIgnoreShizuku() async {
    await _addOrUpdateDbConfig("ignoreShizuku", true.toString());
    _ignoreShizuku.value = true;
  }

  Future<void> setUseAuthentication(bool useAuthentication) async {
    await _addOrUpdateDbConfig(
        "useAuthentication", useAuthentication.toString());
    _useAuthentication.value = useAuthentication;
  }

  Future<void> setAppRevalidateDuration(int appRevalidateDuration) async {
    await _addOrUpdateDbConfig(
        "appRevalidateDuration", appRevalidateDuration.toString());
    _appRevalidateDuration.value = appRevalidateDuration;
  }

  Future<void> setAppPassword(String appPassword) async {
    appPassword = CryptoUtil.toMD5(appPassword);
    await _addOrUpdateDbConfig("appPassword", appPassword);
    _appPassword.value = appPassword;
  }

  Future<void> setEnableSmsSync(bool enableSmsSync) async {
    await _addOrUpdateDbConfig("enableSmsSync", enableSmsSync.toString());
    _enableSmsSync.value = enableSmsSync;
  }

  Future<void> setEnableForward(bool enableForward) async {
    await _addOrUpdateDbConfig("enableForward", enableForward.toString());
    _enableForward.value = enableForward;
  }

  Future<void> setForwardServer(String forwardServer) async {
    await _addOrUpdateDbConfig("forwardServer", forwardServer.toString());
    _forwardServer.value = forwardServer;
  }

  Future<void> setWorkingMode(EnvironmentType workingMode) async {
    await _addOrUpdateDbConfig("workingMode", workingMode.name);
    _workingMode.value = workingMode;
  }
//endregion
}
