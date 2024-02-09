import 'dart:async';

import 'package:clipshare/db/db_util.dart';
import 'package:clipshare/listeners/socket_listener.dart';
import 'package:flutter/material.dart';

import '../main.dart';
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
    await DBUtil.inst.init();
    await SocketListener.inst;
    return Future.value();
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
