import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:basic_utils/basic_utils.dart';
import 'package:clipshare/channels/multi_window_channel.dart';
import 'package:clipshare/entity/dev_info.dart';
import 'package:clipshare/entity/settings.dart';
import 'package:clipshare/entity/tables/device.dart';
import 'package:clipshare/entity/version.dart';
import 'package:clipshare/pages/init.dart';
import 'package:clipshare/pages/windows/compact_window.dart';
import 'package:clipshare/pages/windows/online_devices_window.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/crypto.dart';
import 'package:clipshare/util/extension.dart';
import 'package:clipshare/util/log.dart';
import 'package:clipshare/util/snowflake.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:share_handler_platform_interface/src/data/messages.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  var isMultiWindow = args.firstOrNull == 'multi_window';
  if (!isMultiWindow) {
    ///全局异常捕获
    runZonedGuarded(
      () {
        runApp(RefenaScope(child: const App()));
        SystemUiOverlayStyle systemUiOverlayStyle =
            const SystemUiOverlayStyle(statusBarColor: Colors.transparent);
        SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
      },
      (error, stack) {
        Log.error("App", "$error $stack");
      },
    );
  } else {
    //子窗口
    final windowId = int.parse(args[1]);
    final argument = args[2].isEmpty
        ? const {}
        : jsonDecode(args[2]) as Map<String, dynamic>;
    String tag = argument["tag"];
    Widget? widget;
    switch (tag) {
      case MultiWindowTag.history:
        widget = CompactWindow(
          windowController: WindowController.fromWindowId(windowId),
          args: argument,
        );
        break;
      case MultiWindowTag.devices:
        widget = OnlineDevicesWindow(
          windowController: WindowController.fromWindowId(windowId),
          args: argument,
        );
        break;
    }
    if (widget != null) {
      runApp(widget);
    }
  }
}

//解决 Windows 端 SingleChildScrollView 无法水平滚动的问题
//https://stackoverflow.com/questions/72528980/horizontal-singlechildscrollview-not-working-inside-a-column-on-windows
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods like buildOverscrollIndicator and buildScrollbar
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class App extends StatelessWidget {
  //通用通道
  static const commonChannel = MethodChannel(Constants.channelCommon);

  //剪贴板通道
  static const clipChannel = MethodChannel(Constants.channelClip);

  //Android平台通道
  static const androidChannel = MethodChannel(Constants.channelAndroid);

  static final prime1 = CryptoUtil.getPrime();
  static final prime2 = CryptoUtil.getPrime();
  static const bgColor = Color.fromARGB(255, 238, 238, 238);
  static WindowController? compactWindow;
  static WindowController? onlineDevicesWindow;
  static const mainWindowId = 0;

  static StreamSubscription<SharedMedia>? shareHandlerStream;

  static bool get isSmallScreen =>
      MediaQuery.of(App.context).size.width <= Constants.smallScreenWidth;

  //当前设备id
  static late final DevInfo devInfo;
  static late final Device device;
  static int userId = 0;
  static late final Snowflake snowflake;
  static late BuildContext context;
  static late Settings settings;
  static bool _innerCopy = false;
  static bool authenticating = false;
  static late final Version version;
  static const minVersion = Version("1.0.0-alpha", "3");
  static late double osVersion;

  static bool get innerCopy => _innerCopy;

  //路径
  static late final String documentPath;
  static late final String androidPrivatePicturesPath;
  static late final String cachePath;

  //文件默认存储路径
  static String get defaultFileStorePath {
    var path = "${Directory(Platform.resolvedExecutable).parent.path}/files";
    if (Platform.isAndroid) {
      path = "${Constants.androidDownloadPath}/${Constants.appName}";
    }
    var dir = Directory(path);
    if (!dir.existsSync()) {
      dir.createSync();
    }
    return Directory(path).normalizePath;
  }

  //日志路径
  static String get logsDirPath {
    var path = "${App.cachePath}/logs";
    if (Platform.isWindows) {
      path = Directory(
        "${Directory(Platform.resolvedExecutable).parent.path}/logs",
      ).absolute.normalizePath;
    }
    var dir = Directory(path);
    if (!dir.existsSync()) {
      dir.createSync();
    }
    return Directory(path).normalizePath;
  }

  static final themeData = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
    fontFamily: Platform.isWindows ? 'Microsoft YaHei' : null,
  );
  static const locale = Locale("zh", "CH");
  static const supportedLocales = [
    Locale("zh", "CH"),
    Locale('en', 'US'),
  ];
  static const localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static void setInnerCopy(bool innerCopy) {
    _innerCopy = innerCopy;
    Future.delayed(const Duration(milliseconds: 300), () {
      _innerCopy = false;
    });
  }

  const App({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClipShare',
      scrollBehavior: MyCustomScrollBehavior(),
      theme: themeData,
      //当前运行环境配置
      locale: locale,
      //程序支持的语言环境配置
      supportedLocales: supportedLocales,
      //Material 风格代理配置
      localizationsDelegates: localizationsDelegates,
      home: const LoadingPage(),
    );
  }
}
