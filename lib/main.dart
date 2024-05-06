import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:basic_utils/basic_utils.dart';
import 'package:clipshare/entity/dev_info.dart';
import 'package:clipshare/entity/settings.dart';
import 'package:clipshare/entity/tables/device.dart';
import 'package:clipshare/entity/version.dart';
import 'package:clipshare/pages/compact_page.dart';
import 'package:clipshare/pages/init.dart';
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

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  var isMultiWindow = args.firstOrNull == 'multi_window';
  if (PlatformExt.isMobile || !isMultiWindow) {
    ///全局异常捕获
    runZonedGuarded(
      () {
        runApp(RefenaScope(child: const App()));
        SystemUiOverlayStyle systemUiOverlayStyle =
            SystemUiOverlayStyle(statusBarColor: Colors.transparent);
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
    runApp(
      CompactWindow(
        windowController: WindowController.fromWindowId(windowId),
        args: argument,
      ),
    );
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
        // etc.
      };
}

final themeData = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
  fontFamily: Platform.isWindows ? 'Microsoft YaHei' : null,
);
const locale = Locale("zh", "CH");
const supportedLocales = [
  Locale("zh", "CH"),
  Locale('en', 'US'),
];
const localizationsDelegates = [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];

class App extends StatelessWidget {
  //通用通道
  static const commonChannel = MethodChannel(Constants.channelCommon);

  //剪贴板通道
  static const clipChannel = MethodChannel(Constants.channelClip);

  //Android平台通道
  static const androidChannel = MethodChannel(Constants.channelAndroid);

  static final prime = CryptoUtil.getPrim();
  static final keyPair = CryptoUtils.generateRSAKeyPair();
  static const bgColor = Color.fromARGB(255, 238, 238, 238);
  static WindowController? compactWindow;

  static bool get isSmallScreen =>
      MediaQuery.of(App.context).size.width <= Constants.smallScreenWidth;

  //当前设备id
  static late final DevInfo devInfo;
  static late final Device device;
  static int userId = 0;
  static late final Snowflake snowflake;
  static late BuildContext context;
  static late Settings settings;
  static bool innerCopy = false;
  static bool authenticating = false;
  static late final Version version;
  static const minVersion = Version("1.0.0-alpha", "3");
  static late double osVersion;

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
