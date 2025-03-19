import 'package:clipshare/app/modules/views/windows/history/history_page.dart';
import 'package:clipshare/app/services/window_control_service.dart';
import 'package:clipshare/app/theme/app_theme.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
      theme: lightThemeData,
      darkTheme: darkThemeData,
      themeMode: ThemeMode.system,
      //当前运行环境配置
      locale: Constants.defaultLocale,
      //程序支持的语言环境配置
      supportedLocales: Constants.supportedLocales,
      //Material 风格代理配置
      localizationsDelegates: Constants.localizationsDelegates,
      home: const HistoryPage(),
    );
  }
}
