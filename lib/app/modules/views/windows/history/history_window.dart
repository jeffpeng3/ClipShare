import 'package:clipshare/app/theme/app_theme.dart';
import 'package:clipshare/app/modules/views/windows/history/history_page.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';

class HistoryWindow extends StatelessWidget {
  final WindowController windowController;
  final Map? args;

  const HistoryWindow({
    super.key,
    required this.windowController,
    required this.args,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '历史记录',
      theme: themeData,
      //当前运行环境配置
      locale: locale,
      //程序支持的语言环境配置
      supportedLocales: supportedLocales,
      //Material 风格代理配置
      localizationsDelegates: localizationsDelegates,
      home: const CompactPage(),
    );
  }
}
