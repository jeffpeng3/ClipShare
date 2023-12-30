import 'dart:async';

import 'package:clipshare/db/db_util.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 在这里执行初始化操作，比如加载数据或设置计时器
    _loadData();
  }

  // 例子：模拟加载数据的方法
  Future<void> _loadData() async {
    DBUtil.inst.init().then((value) =>
      // 数据加载完成后，导航到下一个页面
      Navigator.pushReplacementNamed(context, '/home')
    ); // 替换成你的目标页面
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
