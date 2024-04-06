import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:clipshare/db/app_db.dart';
import 'package:clipshare/entity/dev_info.dart';
import 'package:clipshare/entity/settings.dart';
import 'package:clipshare/entity/tables/device.dart';
import 'package:clipshare/entity/tables/history.dart';
import 'package:clipshare/entity/version.dart';
import 'package:clipshare/listeners/clip_listener.dart';
import 'package:clipshare/listeners/socket_listener.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/pages/guide/battery_perm_guide.dart';
import 'package:clipshare/pages/guide/float_perm_guide.dart';
import 'package:clipshare/pages/guide/notify_perm_guide.dart';
import 'package:clipshare/pages/guide/shizuku_perm_guide.dart';
import 'package:clipshare/pages/user_guide.dart';
import 'package:clipshare/provider/device_info_provider.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/crypto.dart';
import 'package:clipshare/util/extension.dart';
import 'package:clipshare/util/snowflake.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:screen_retriever/screen_retriever.dart';
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
        gotoUserGuidePage();
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
    //加载配置后初始化窗体配置
    if (Platform.isWindows) {
      await initWindowsManager();
      await initHotKey();
      initMultiWindowEvent();
    }
    // 初始化channel
    initChannel();
    return Future.value();
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
      }
      //都不符合，返回空
      return Future.value();
    });
  }

  void initChannel() {
    App.clipChannel.setMethodCallHandler((call) async {
      var arguments = call.arguments;
      switch (call.method) {
        case "setClipText":
          String text = arguments['text'];
          ClipListener.inst.update(text);
          debugPrint("clipboard changed: $text");
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
      backgroundColor: Colors.transparent,
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
    );
    if (App.settings.showHistoryFloat) {
      App.androidChannel.invokeMethod("showHistoryFloatWindow");
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
    // For hot reload, `unregisterAll()` needs to be called.
    await hotKeyManager.unregisterAll();
    // ctrl + alt + h
    HotKey _hotKey = HotKey(
      key: PhysicalKeyboardKey.keyH,
      modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
      // Set hotkey scope (default is HotKeyScope.system)
      scope: HotKeyScope.system,
    );
    await hotKeyManager.register(
      _hotKey,
      keyDownHandler: (hotKey) async {
        var ids = List.empty();
        try {
          ids = await DesktopMultiWindow.getAllSubWindowIds();
        } catch (e) {
          ids = List.empty();
        }
        //只允许弹窗一次
        if (ids.isNotEmpty) {
          return;
        }
        //createWindow里面的参数必须传
        final window = await DesktopMultiWindow.createWindow("");
        var offset = await screenRetriever.getCursorScreenPoint();
        //多显示器不知道怎么判断鼠标在哪个显示器中，所以默认主显示器
        Size screenSize = (await screenRetriever.getPrimaryDisplay()).size;
        final [width, height] = [320.0, 515.0];
        final maxX = screenSize.width - width;
        final maxY = screenSize.height - height;
        //限制在屏幕范围内
        final [x, y] = [min(maxX, offset.dx), min(maxY, offset.dy)];
        window
          ..setFrame(Offset(x, y) & Size(width, height))
          ..setTitle('历史记录')
          ..show();
        // Future.delayed(const Duration(seconds: 2),(){
        //   window.show();
        // });
      },
    );
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

  void gotoUserGuidePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserGuide(
          guides: [
            FloatPermGuide(),
            ShizukuPermGuide(),
            NotifyPermGuide(),
            BatteryPermGuide(),
          ],
        ),
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
