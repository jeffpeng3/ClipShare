import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clipshare/db/app_db.dart';
import 'package:clipshare/entity/dev_info.dart';
import 'package:clipshare/entity/settings.dart';
import 'package:clipshare/entity/tables/device.dart';
import 'package:clipshare/entity/tables/history.dart';
import 'package:clipshare/entity/version.dart';
import 'package:clipshare/handler/hot_key_handler.dart';
import 'package:clipshare/handler/socket/secure_socket_client.dart';
import 'package:clipshare/listeners/clip_listener.dart';
import 'package:clipshare/listeners/socket_listener.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/pages/welcome_page.dart';
import 'package:clipshare/provider/device_info_provider.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/crypto.dart';
import 'package:clipshare/util/extension.dart';
import 'package:clipshare/util/log.dart';
import 'package:clipshare/util/snowflake.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:window_manager/window_manager.dart';

import 'nav/base_page.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
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
    // var dirs = await getExternalStorageDirectory();
    // print(dirs);
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
      // /storage/emulated/0/Android/data/top.coclyun.clipshare/cache
      App.cachePath = (await getExternalCacheDirectories())![0].path;
    } else {
      App.documentPath = (await getApplicationDocumentsDirectory()).path;
      App.cachePath = (await getApplicationCacheDirectory()).path;
    }
    App.logsDirPath = "${App.cachePath}/logs";
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
        case "getHistories":
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
        case "copy":
          int id = args["id"];
          AppDb.inst.historyDao.getById(id).then(
            (res) {
              if (res == null) return;
              App.innerCopy = true;
              App.clipChannel.invokeMethod("copy", res.toJson());
            },
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
        case "onClipboardChanged":
          String content = arguments['content'];
          String type = arguments['type'];
          ClipListener.inst.update(ContentType.parse(type), content);
          debugPrint("clipboard changed: $type: $content");
          return Future(() => true);
        case "getHistory":
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
          case "onScreenOpened":
            //此处应该发送socket通知同步剪贴板到本机
            SocketListener.inst.sendData(null, MsgType.reqMissingData, {});
            break;
          case "checkMustPermission":
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('必要权限缺失'),
                  content: const Text(
                    '请授权必要权限，由于 Android 10 及以上版本的系统不允许后台读取剪贴板，需要依赖 Shizuku 或 Root 权限来提权，否则只能被动接收剪贴板数据而不能发送',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        // 关闭弹窗
                        Navigator.of(context).pop();
                      },
                      child: const Text('再也不说了'),
                    ),
                    TextButton(
                      onPressed: () {
                        // 关闭弹窗
                        Navigator.of(context).pop();
                      },
                      child: const Text('确定'),
                    ),
                  ],
                );
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
    var heartbeatInterval = await cfg.getConfig(
      "heartbeatInterval",
      App.userId,
    );
    var fileStorePath = await cfg.getConfig(
      "fileStorePath",
      App.userId,
    );
    var fileStoreDir =
        Directory(fileStorePath ?? Constants.defaultFileStorePath);
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
      heartbeatInterval:
          heartbeatInterval?.toInt() ?? Constants.heartbeatInterval,
      fileStorePath: fileStoreDir.absolute.normalizePath,
    );
    //判断路径是否存在，不存在则创建,todo
    if (!fileStoreDir.existsSync()) {
      try {
        fileStoreDir.createSync();
      } catch (e) {
        var dirPath = await FilePicker.platform.getDirectoryPath();
      }
    }
    if (Platform.isAndroid) {
      if (App.settings.showHistoryFloat) {
        App.androidChannel.invokeMethod("showHistoryFloatWindow");
      }
      App.androidChannel.invokeMethod(
        "lockHistoryFloatLoc",
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
