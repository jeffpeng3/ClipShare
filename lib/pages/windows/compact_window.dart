import 'package:clipshare/main.dart';
import 'package:clipshare/pages/compact_page.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';

class CompactWindow extends StatefulWidget {
  final WindowController windowController;
  final Map? args;

  const CompactWindow({
    super.key,
    required this.windowController,
    required this.args,
  });

  @override
  State<StatefulWidget> createState() {
    return _CompactWindowState();
  }
}

class _CompactWindowState extends State<CompactWindow> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '历史记录',
      theme: App.themeData,
      //当前运行环境配置
      locale: App.locale,
      //程序支持的语言环境配置
      supportedLocales: App.supportedLocales,
      //Material 风格代理配置
      localizationsDelegates: App.localizationsDelegates,
      home: const CompactPage(),
    );
  }
}
