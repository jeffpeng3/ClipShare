import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:clipshare/app/data/enums/multi_window_tag.dart';
import 'package:clipshare/app/data/models/desktop_multi_window_args.dart';
import 'package:clipshare/app/modules/views/windows/history/history_window.dart';
import 'package:clipshare/app/modules/views/windows/online_devices/online_devices_window.dart';
import 'package:clipshare/app/routes/app_pages.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/channels/clip_channel.dart';
import 'package:clipshare/app/services/channels/multi_window_channel.dart';
import 'package:clipshare/app/services/device_service.dart';
import 'package:clipshare/app/services/socket_service.dart';
import 'package:clipshare/app/services/syncing_file_progress_service.dart';
import 'package:clipshare/app/services/tag_service.dart';
import 'package:clipshare/app/services/tray_service.dart';
import 'package:clipshare/app/services/window_service.dart';
import 'package:clipshare/app/translations/app_translations.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
// import 'package:workmanager/workmanager.dart';

import 'app/modules/splash_module/splash_page.dart';
import 'app/services/config_service.dart';
import 'app/services/db_service.dart';
import 'app/theme/app_theme.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  Widget home = SplashPage();
  String title = 'ClipShare';
  var isMultiWindow = args.firstOrNull == 'multi_window';
  DesktopMultiWindowArgs? multiWindowArgs;
  if (isMultiWindow) {
    //子窗口
    final windowId = int.parse(args[1]);
    multiWindowArgs = DesktopMultiWindowArgs.fromJson(jsonDecode(args[2]));
    switch (multiWindowArgs.tag) {
      case MultiWindowTag.history:
        home = HistoryWindow(
          windowController: WindowController.fromWindowId(windowId),
          args: multiWindowArgs.otherArgs,
        );
        title = multiWindowArgs.title;
        break;
      case MultiWindowTag.devices:
        home = OnlineDevicesWindow(
          windowController: WindowController.fromWindowId(windowId),
          args: multiWindowArgs.otherArgs,
        );
        title = multiWindowArgs.title;
        break;
    }
  }
  if (isMultiWindow) {
    Get.put(MultiWindowChannelService());
    runMain(home, title, multiWindowArgs);
  } else {
    await initServices();
    runMain(home, title, null);
  }
}

Future<void> initServices() async {
  await Get.putAsync(() => DbService().init());
  await Get.putAsync(() => ConfigService().init());
  Get.put<SocketService>(SocketService(), permanent: true);
  Get.put(AndroidChannelService().init());
  Get.put(ClipChannelService().init());
  Get.put(MultiWindowChannelService());
  await Get.putAsync(() => DeviceService().init(), permanent: true);
  await Get.putAsync(() => TagService().init(), permanent: true);
  await Get.putAsync(
    () => SyncingFileProgressService().init(),
    permanent: true,
  );
  if (PlatformExt.isDesktop) {
    await Get.putAsync(() => WindowService().init());
    await Get.putAsync(() => TrayService().init());
  }
  // 在 main 函数中初始化 WorkManager
  // Workmanager().initialize(callbackDispatcher);
}

// @pragma('vm:entry-point')
// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) {
//     print("任务开始执行：$task");
//
//     // 这里是任务执行的内容
//     if (task == "autoCloseConn") {
//       final ss = Get.find<SocketService>();
//       ss.autoCloseConnTimer = null;
//       Log.debug("callbackDispatcher", "autoCloseConn exec");
//     }
//
//     return Future.value(true); // 返回 true 表示任务成功完成
//   });
// }

void runMain(Widget home, String title, DesktopMultiWindowArgs? args) {
  final isDarkMode =
      args?.themeMode == ThemeMode.dark || Get.isPlatformDarkMode;
  Locale? locale;
  final isMultiWindow = args != null;
  if (isMultiWindow) {
    locale = Locale(args.languageCode, args.countryCode);
  }
  runApp(
    ThemeProvider(
      initTheme: isDarkMode ? darkThemeData : lightThemeData,
      builder: (context, theme) {
        return GetMaterialApp(
          translations: AppTranslation(),
          defaultTransition: Transition.native,
          title: title,
          initialRoute: isMultiWindow ? null : Routes.SPLASH,
          getPages: isMultiWindow ? null : AppPages.pages,
          theme: theme,
          home: isMultiWindow ? home : null,
          darkTheme: darkThemeData,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          locale: locale,
          fallbackLocale: const Locale('en', 'US'),
          supportedLocales: Constants.supportedLocales,
          localizationsDelegates: Constants.localizationsDelegates,
          scrollBehavior: MyCustomScrollBehavior(),
        );
      },
    ),
  );
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
