import 'dart:io';

import 'package:clipshare/entity/dev_info.dart';
import 'package:clipshare/pages/nav/base_page.dart';
import 'package:clipshare/pages/splash.dart';
import 'package:clipshare/pages/tag_edit_page.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/log.dart';
import 'package:clipshare/util/snowflake.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:fluttertoast/fluttertoast.dart';
void main() async {
  if (Platform.isWindows) {
    await initWindowsManager();
  }
  var list = await NetworkInterface.list();
  Log.debug("ip list", list);
  runApp(const App());
}

Future<void> initWindowsManager() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 必须加上这一行。
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  return Future<void>.value();
}

class App extends StatelessWidget {
  //通用通道
  static const commonChannel = MethodChannel(Constants.channelCommon);

  //剪贴板通道
  static const clipChannel = MethodChannel(Constants.channelClip);

  //Android平台通道
  static const androidChannel = MethodChannel(Constants.channelAndroid);

  //当前设备id
  static late final DevInfo devInfo;
  static String userId = "0";
  static late final Snowflake snowflake;
  static late final FToast toast;
  static late BuildContext context;

  const App({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: FToastBuilder(),
      title: 'ClipShare',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
      ),
      home: const SplashScreen(),
    );
  }
}
