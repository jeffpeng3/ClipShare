import 'dart:async';

import 'package:clipshare/db/db_util.dart';
import 'package:clipshare/listeners/socket_listener.dart';
import 'package:flutter/material.dart';

import '../entity/dev_info.dart';
import '../main.dart';
import '../util/crypto.dart';
import '../util/log.dart';
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
    //初始化socket
    await SocketListener.inst;
    return Future.value();
  }

  ///调用平台方法，获取设备信息
  Future<void> initDevInfo() {
    return App.commonChannel.invokeMethod("getBaseInfo").then((data) {
      String guid = data['guid'];
      String name = data['dev'];
      String type = data['type'];
      Log.debug("baseInfo", "$guid $name $type");
      App.devInfo = DevInfo(CryptoUtil.toMD5(guid), name, type);
      App.snowflake = Snowflake(guid.hashCode);
    });
  }

  void gotoHomePage() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const HomePage(title: 'Flutter Demo'),
        ));
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
