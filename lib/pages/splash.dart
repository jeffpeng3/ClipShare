import 'dart:async';
import 'dart:io';

import 'package:clipshare/db/db_util.dart';
import 'package:clipshare/entity/settings.dart';
import 'package:clipshare/listeners/clip_listener.dart';
import 'package:clipshare/listeners/socket_listener.dart';
import 'package:clipshare/pages/guide/battery_perm_guide.dart';
import 'package:clipshare/pages/guide/float_perm_guide.dart';
import 'package:clipshare/pages/guide/notify_perm_guide.dart';
import 'package:clipshare/pages/guide/shizuku_perm_guide.dart';
import 'package:clipshare/pages/user_guide.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/extension.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:window_manager/window_manager.dart';

import '../entity/dev_info.dart';
import '../entity/tables/device.dart';
import '../main.dart';
import '../util/crypto.dart';
import '../util/snowflake.dart';
import 'nav/base_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
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
    await DBUtil.inst.init();
    //初始化本机设备信息
    await initDevInfo();
    //加载配置信息
    await loadConfigs();
    //初始化socket
    SocketListener.inst.init(context.ref);
    // 初始化channel
    if (Platform.isAndroid) {
      //接收平台消息
      App.clipChannel.setMethodCallHandler((call) {
        switch (call.method) {
          case "setClipText":
            {
              String text = call.arguments['text'];
              ClipListener.inst.update(text);
              debugPrint("clipboard changed: $text");
              return Future(() => true);
            }
        }
        return Future(() => false);
      });
      App.androidChannel.setMethodCallHandler((call) {
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
    return Future.value();
  }

  ///加载配置信息
  Future<void> loadConfigs() async {
    var cfg = DBUtil.inst.configDao;
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
    App.settings = Settings(
      port: port?.toInt() ?? Constants.port,
      localName:
          localName != null && localName != "" ? localName : App.devInfo.name,
      startMini: startMini?.toBool() ?? false,
      launchAtStartup: launchAtStartup?.toBool() ?? false,
      allowDiscover: allowDiscover?.toBool() ?? true,
      showHistoryFloat: showHistoryFloat?.toBool() ?? false,
      firstStartup: firstStartup?.toBool() ?? true,
    );
    if (App.settings.showHistoryFloat) {
      App.androidChannel.invokeMethod("showHistoryFloatWindow");
    }
    App.devInfo.name = App.settings.localName;
    if (!App.settings.startMini && PlatformExt.isPC) {
      await windowManager.show();
      await windowManager.focus();
    }
  }

  ///调用平台方法，获取设备信息
  Future<void> initDevInfo() async {
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

  void gotoHomePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BasePage(title: 'ChipShare'),
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
    return const Scaffold(
      body: Center(
        child: Text("加载中..."),
      ),
    );
  }
}
