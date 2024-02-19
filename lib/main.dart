import 'dart:io';
import 'dart:ui';

import 'package:clipshare/entity/dev_info.dart';
import 'package:clipshare/pages/splash.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/log.dart';
import 'package:clipshare/util/snowflake.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:window_manager/window_manager.dart';

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
//解决 Windows 端 SingleChildScrollView 无法水平滚动的问题
//https://stackoverflow.com/questions/72528980/horizontal-singlechildscrollview-not-working-inside-a-column-on-windows
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods like buildOverscrollIndicator and buildScrollbar
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    // etc.
  };
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
  static int userId = 0;
  static late final Snowflake snowflake;
  static late BuildContext context;

  const App({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: FToastBuilder(),
      title: 'ClipShare',
      scrollBehavior: MyCustomScrollBehavior(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
      ),
      home: const SplashScreen(),
    );
  }
}
