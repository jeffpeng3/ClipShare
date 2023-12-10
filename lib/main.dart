import 'package:clipshare/entity/dev_info.dart';
import 'package:clipshare/pages/base_page.dart';
import 'package:clipshare/pages/splash.dart';
import 'package:clipshare/util/snowflake.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  //通用通道
  static const commonChannel = MethodChannel('common');

  //剪贴板通道
  static const clipChannel = MethodChannel('clip');

  //Android平台通道
  static const androidChannel = MethodChannel('android');

  //当前设备id
  static late final DevInfo devInfo;
  static String userId = "0";
  static late Snowflake snowflake;

  const App({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClipShare',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
      ),
      home: const SplashScreen(),
      routes: {'/home': (context) => const HomePage(title: 'Flutter Demo')},
    );
  }
}
