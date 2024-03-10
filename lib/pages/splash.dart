import 'dart:async';
import 'dart:io';

import 'package:clipshare/db/db_util.dart';
import 'package:clipshare/entity/settings.dart';
import 'package:clipshare/listeners/socket_listener.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/extension.dart';
import 'package:clipshare/util/platform_util.dart';
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
      // 初始化完成，导航到下一个页面c
      gotoHomePage();
    });
  }

  Future<void> init() async {
    //初始化数据库
    await DBUtil.inst.init();
    //初始化本机设备信息
    await initDevInfo();
    //加载配置信息
    await loadConfigs();
    //初始化socket
    SocketListener.inst.init(context.ref);
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
    App.settings = Settings(
      port: port?.toInt() ?? Constants.port,
      localName: localName ?? App.devInfo.name,
      startMini: startMini?.toBool() ?? false,
      launchAtStartup: launchAtStartup?.toBool() ?? false,
      allowDiscover: allowDiscover?.toBool() ?? false,
    );
    if (!App.settings.startMini && PlatformUtil.isPC()) {
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
        builder: (context) => const HomePage(title: 'ChipShare'),
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
