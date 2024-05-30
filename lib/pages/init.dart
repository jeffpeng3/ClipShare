import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clipshare/channels/android_channel.dart';
import 'package:clipshare/channels/clip_channel.dart';
import 'package:clipshare/channels/multi_window_channel.dart';
import 'package:clipshare/db/app_db.dart';
import 'package:clipshare/entity/dev_info.dart';
import 'package:clipshare/entity/settings.dart';
import 'package:clipshare/entity/tables/device.dart';
import 'package:clipshare/entity/tables/history.dart';
import 'package:clipshare/entity/version.dart';
import 'package:clipshare/handler/hot_key_handler.dart';
import 'package:clipshare/handler/socket/secure_socket_client.dart';
import 'package:clipshare/handler/sync/file_syncer.dart';
import 'package:clipshare/listeners/clipboard_listener.dart';
import 'package:clipshare/listeners/screen_opened_listener.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/pages/nav/devices_page.dart';
import 'package:clipshare/pages/online_devices_page.dart';
import 'package:clipshare/pages/syncing_file_page.dart';
import 'package:clipshare/pages/welcome_page.dart';
import 'package:clipshare/provider/device_info_provider.dart';
import 'package:clipshare/provider/setting_provider.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/crypto.dart';
import 'package:clipshare/util/extension.dart';
import 'package:clipshare/util/global.dart';
import 'package:clipshare/util/log.dart';
import 'package:clipshare/util/snowflake.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:share_handler/share_handler.dart';
import 'package:window_manager/window_manager.dart';

import 'nav/base_page.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  static const tag = "init";

  @override
  void initState() {
    super.initState();
    // 在这里执行初始化操作
    init().then((v) {
      // 初始化完成，导航到下一个页面
      if (App.settings.firstStartup && Platform.isAndroid) {
        gotoWelcomePage();
      } else {
        gotoHomePage();
      }
    });
  }

  Future<void> init() async {
    App.context = context;
    //初始化数据库
    await AppDb.inst.init();
    //初始化本机设备信息
    await initDevInfo();
    //加载配置信息
    await loadConfigs();
    // 初始化App路径
    initPath();
    //加载配置后初始化窗体配置
    if (Platform.isWindows) {
      await initWindowsManager();
      await initHotKey();
      initMultiWindowEvent();
    }
    // 初始化channel
    initChannel();
    initShareHandler();
    try {
      //不知道为什么必须调用一次connect，不论是否成功，否则进入主页时必定卡顿两秒钟
      SecureSocketClient.connect(
        ip: "0.0.0.0",
        port: Constants.port,
        prime: App.prime,
        keyPair: App.keyPair,
      );
    } catch (e) {}
    return Future.value();
  }

  void initPath() async {
    if (Platform.isAndroid) {
      // /storage/emulated/0/Android/data/top.coclyun.clipshare/files/documents
      App.documentPath = (await getExternalStorageDirectories(
        type: StorageDirectory.documents,
      ))![0]
          .path;
      App.androidPrivatePicturesPath = (await getExternalStorageDirectories(
        type: StorageDirectory.pictures,
      ))![0]
          .path;
      // /storage/emulated/0/Android/data/top.coclyun.clipshare/cache
      App.cachePath = (await getExternalCacheDirectories())![0].path;
    } else {
      App.documentPath = (await getApplicationDocumentsDirectory()).path;
      App.cachePath = (await getApplicationCacheDirectory()).path;
    }
    Log.debug("init", "documentPath, ${App.documentPath}");
    Log.debug("init", "cachePath, ${App.cachePath}");
  }

  void initMultiWindowEvent() {
    //处理弹窗事件
    DesktopMultiWindow.setMethodHandler((
      MethodCall call,
      int fromWindowId,
    ) async {
      var args = jsonDecode(call.arguments);
      switch (call.method) {
        case MultiWindowMethod.getHistories:
          int fromId = args["fromId"];
          var historyDao = AppDb.inst.historyDao;
          var lst = List<History>.empty();
          if (fromId == 0) {
            lst = await historyDao.getHistoriesTop20(App.userId);
          } else {
            lst = await historyDao.getHistoriesPage(App.userId, fromId);
          }
          var devInfos = context.ref.read(DeviceInfoProvider.inst);
          var devMap = devInfos.toIdNameMap();
          devMap[App.devInfo.guid] = "本机";
          var res = {
            "list": lst,
            "devInfos": devMap,
          };
          return jsonEncode(res);
        case MultiWindowMethod.copy:
          int id = args["id"];
          AppDb.inst.historyDao.getById(id).then(
            (res) {
              if (res == null) return;
              App.setInnerCopy(true);
              ClipChannel.copy(res.toJson());
            },
          );
          break;
        case MultiWindowMethod.getCompatibleOnlineDevices:
          var devices =
              DevicesPage.pageKey.currentState?.getCompatibleOnlineDevices() ??
                  [];
          Log.info(tag, "devices $devices");
          return jsonEncode(devices);
        case MultiWindowMethod.syncFiles:
          var files = (args["files"] as List<dynamic>).cast<String>();
          var devices = List<Device>.empty(growable: true);
          for (var devMap in (args["devices"] as List<dynamic>)) {
            devices.add(Device.fromJson(devMap));
          }
          Log.info(tag, "files $files");
          Log.info(tag, "devIds $devices");
          FileSyncer.sendFiles(
            devices: devices,
            paths: files,
            context: context,
          );
          break;
      }
      //都不符合，返回空
      return Future.value();
    });
  }

  void initChannel() {
    App.clipChannel.setMethodCallHandler((call) async {
      var arguments = call.arguments;
      switch (call.method) {
        case ClipChannelMethod.onClipboardChanged:
          String content = arguments['content'];
          String type = arguments['type'];
          ClipboardListener.inst.update(ContentType.parse(type), content);
          Log.debug(tag, "clipboard changed: $type: $content");
          return Future(() => true);
        case ClipChannelMethod.getHistory:
          int fromId = arguments["fromId"];
          var historyDao = AppDb.inst.historyDao;
          var lst = List<History>.empty();
          if (fromId == 0) {
            lst = await historyDao.getHistoriesTop20(App.userId);
          } else {
            lst = await historyDao.getHistoriesPage(App.userId, fromId);
          }
          var contentLst = lst
              .map(
                (e) => {
                  "id": e.id,
                  "content": e.content,
                },
              )
              .toList();
          return Future(() => contentLst);
      }
      return Future(() => false);
    });
    if (Platform.isAndroid) {
      App.androidChannel.setMethodCallHandler((call) async {
        var arguments = call.arguments;
        switch (call.method) {
          case AndroidChannelMethod.onScreenOpened:
            ScreenOpenedListener.inst.notify();
            break;
          case AndroidChannelMethod.checkMustPermission:
            try {
              if (App.settings.firstStartup || App.settings.ignoreShizuku) {
                return;
              }
            } catch (e) {
              return;
            }
            Global.showTipsDialog(
              context: context,
              title: '必要权限缺失',
              text: '请授权必要权限，由于 Android 10 及以上版本的系统不允许后台读取剪贴板，'
                  '需要依赖 Shizuku，否则只能被动接收剪贴板数据而不能自动同步',
              cancelText: '不再提示',
              onCancel: () {
                context.ref.notifier(settingProvider).ignoreShizuku();
              },
            );
            break;
        }
        return Future(() => false);
      });
    }
  }

  Future<void> initWindowsManager() async {
    WidgetsFlutterBinding.ensureInitialized();
    // 必须加上这一行。
    await windowManager.ensureInitialized();
    final [weight, height] =
        App.settings.windowSize.split("x").map((e) => e.toDouble()).toList();
    WindowOptions windowOptions = WindowOptions(
      size: Size(weight, height),
      center: true,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () {
      if (!App.settings.startMini) {
        windowManager.show();
        windowManager.focus();
      }
    });
    return Future<void>.value();
  }

  Future<void> initShareHandler() async {
    if (!Platform.isAndroid) {
      return;
    }
    final handler = ShareHandlerPlatform.instance;
    App.shareHandlerStream?.cancel();
    App.shareHandlerStream =
        handler.sharedMediaStream.listen((SharedMedia media) {
      Log.info(tag, media);
      if (media.attachments == null) {
        return;
      }
      var files = media.attachments!
          .where((attachment) => attachment != null)
          .map((attachment) => attachment!.path)
          .toList();
      Log.debug(tag, files);
      if (files.isEmpty) {
        return;
      }
      var devices =
          DevicesPage.pageKey.currentState?.getCompatibleOnlineDevices() ?? [];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OnlineDevicesPage(
            showAppBar: true,
            devices: devices,
            onSendClicked: (List<Device> selectedDevices) {
              FileSyncer.sendFiles(
                devices: selectedDevices,
                paths: files,
                context: context,
              );
            },
          ),
        ),
      );
    });
  }

  ///加载配置信息
  Future<void> loadConfigs() async {
    var cfg = AppDb.inst.configDao;
    var port = await cfg.getConfig(
      "port",
      App.userId,
    );
    var localName = await cfg.getConfig(
      "localName",
      App.userId,
    );
    var startMini = await cfg.getConfig(
      "startMini",
      App.userId,
    );
    var launchAtStartup = await cfg.getConfig(
      "launchAtStartup",
      App.userId,
    );
    var allowDiscover = await cfg.getConfig(
      "allowDiscover",
      App.userId,
    );
    var showHistoryFloat = await cfg.getConfig(
      "showHistoryFloat",
      App.userId,
    );
    var firstStartup = await cfg.getConfig(
      "firstStartup",
      App.userId,
    );
    var windowSize = await cfg.getConfig(
      "windowSize",
      App.userId,
    );
    var rememberWindowSize = await cfg.getConfig(
      "rememberWindowSize",
      App.userId,
    );
    var lockHistoryFloatLoc = await cfg.getConfig(
      "lockHistoryFloatLoc",
      App.userId,
    );
    var enableLogsRecord = await cfg.getConfig(
      "enableLogsRecord",
      App.userId,
    );
    var tagRegulars = await cfg.getConfig(
      "tagRegulars",
      App.userId,
    );
    var historyWindowKeys = await cfg.getConfig(
      "historyWindowHotKeys",
      App.userId,
    );
    var syncFileHotKeys = await cfg.getConfig(
      "syncFileHotKeys",
      App.userId,
    );
    var heartbeatInterval = await cfg.getConfig(
      "heartbeatInterval",
      App.userId,
    );
    var fileStorePath = await cfg.getConfig(
      "fileStorePath",
      App.userId,
    );
    var saveToPictures = await cfg.getConfig(
      "saveToPictures",
      App.userId,
    );
    var ignoreShizuku = await cfg.getConfig(
      "ignoreShizuku",
      App.userId,
    );
    var useAuthentication = await cfg.getConfig(
      "useAuthentication",
      App.userId,
    );
    var appRevalidateDuration = await cfg.getConfig(
      "appRevalidateDuration",
      App.userId,
    );
    var appPassword = await cfg.getConfig(
      "appPassword",
      App.userId,
    );
    var fileStoreDir = Directory(fileStorePath ?? App.defaultFileStorePath);
    App.settings = Settings(
      port: port?.toInt() ?? Constants.port,
      localName: localName.isNotNullAndEmpty ? localName! : App.devInfo.name,
      startMini: startMini?.toBool() ?? false,
      launchAtStartup: launchAtStartup?.toBool() ?? false,
      allowDiscover: allowDiscover?.toBool() ?? true,
      showHistoryFloat: showHistoryFloat?.toBool() ?? false,
      firstStartup: firstStartup?.toBool() ?? true,
      windowSize:
          windowSize.isNullOrEmpty || rememberWindowSize?.toBool() != true
              ? Constants.defaultWindowSize
              : windowSize!,
      rememberWindowSize: rememberWindowSize?.toBool() ?? false,
      lockHistoryFloatLoc: lockHistoryFloatLoc?.toBool() ?? true,
      enableLogsRecord: enableLogsRecord?.toBool() ?? false,
      tagRegulars: tagRegulars ?? Constants.defaultTags,
      historyWindowHotKeys:
          historyWindowKeys ?? Constants.defaultHistoryWindowKeys,
      syncFileHotKeys: syncFileHotKeys ?? Constants.defaultSyncFileHotKeys,
      heartbeatInterval:
          heartbeatInterval?.toInt() ?? Constants.heartbeatInterval,
      fileStorePath: fileStoreDir.absolute.normalizePath,
      saveToPictures: saveToPictures?.toBool() ?? false,
      ignoreShizuku: ignoreShizuku?.toBool() ?? false,
      useAuthentication: useAuthentication?.toBool() ?? false,
      appRevalidateDuration: appRevalidateDuration?.toInt() ?? 0,
      appPassword: appPassword,
    );
    if (Platform.isAndroid) {
      if (App.settings.showHistoryFloat) {
        AndroidChannel.showHistoryFloatWindow();
      }
      AndroidChannel.lockHistoryFloatLoc(
        {"loc": App.settings.lockHistoryFloatLoc},
      );
    }
    App.devInfo.name = App.settings.localName;
  }

  ///调用平台方法，获取设备信息
  Future<void> initDevInfo() async {
    //读取版本信息
    var pkgInfo = await PackageInfo.fromPlatform();
    App.version = Version(pkgInfo.version, pkgInfo.buildNumber);
    //读取设备id信息
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      var androidInfo = await deviceInfo.androidInfo;
      var guid = CryptoUtil.toMD5(androidInfo.id);
      var name = androidInfo.model;
      var type = "Android";
      App.devInfo = DevInfo(guid, name, type);
      App.device = Device(
        guid: guid,
        devName: "本机",
        uid: App.userId,
        type: type,
      );
      var release = androidInfo.version.release;
      App.osVersion = RegExp(r"\d+").firstMatch(release)!.group(0)!.toDouble();
    } else if (Platform.isWindows) {
      var windowsInfo = await deviceInfo.windowsInfo;
      var guid = CryptoUtil.toMD5(windowsInfo.deviceId);
      var name = windowsInfo.computerName;
      var type = "Windows";
      App.devInfo = DevInfo(guid, name, type);
      App.device = Device(
        guid: guid,
        devName: "本机",
        uid: App.userId,
        type: type,
      );
    } else {
      throw Exception("Not Support Platform");
    }
    App.snowflake = Snowflake(App.device.guid.hashCode);
  }

  ///初始化快捷键
  initHotKey() async {
    await AppHotKeyHandler.unRegisterAll();
    var hotKey =
        AppHotKeyHandler.toSystemHotKey(App.settings.historyWindowHotKeys);
    AppHotKeyHandler.registerHistoryWindow(hotKey);
    hotKey = AppHotKeyHandler.toSystemHotKey(App.settings.syncFileHotKeys);
    AppHotKeyHandler.registerFileSync(hotKey);
  }

  void gotoHomePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BasePage(
          key: BasePage.pageKey,
        ),
      ),
    );
  }

  void gotoWelcomePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WelcomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/images/logo/logo.png',
          width: 100,
          height: 100,
        ),
      ),
    );
  }
}
