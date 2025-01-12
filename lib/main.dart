import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:animated_theme_switcher/animated_theme_switcher.dart';
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
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/modules/splash_module/splash_page.dart';
import 'app/services/config_service.dart';
import 'app/services/db_service.dart';
import 'app/theme/app_theme.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  Widget home = SplashPage();
  String title = 'ClipShare';
  var isMultiWindow = args.firstOrNull == 'multi_window';
  if (isMultiWindow) {
    //子窗口
    final windowId = int.parse(args[1]);
    final argument = args[2].isEmpty
        ? const {}
        : jsonDecode(args[2]) as Map<String, dynamic>;
    String tag = argument["tag"];
    switch (tag) {
      case MultiWindowTag.history:
        home = HistoryWindow(
          windowController: WindowController.fromWindowId(windowId),
          args: argument,
        );
        title = '历史记录';
        break;
      case MultiWindowTag.devices:
        home = OnlineDevicesWindow(
          windowController: WindowController.fromWindowId(windowId),
          args: argument,
        );
        title = '设备列表';
        break;
    }
  }
  if (isMultiWindow) {
    Get.put(MultiWindowChannelService());
    runApp(home);
  } else {
    await initServices();
    runMain(home, title);
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
}

void runMain(Widget home, String title) {
  runApp(
    ThemeProvider(
      initTheme: Get.isPlatformDarkMode ? darkThemeData : lightThemeData,
      builder: (context, theme) {
        return GetMaterialApp(
          translations: AppTranslation(),
          defaultTransition: Transition.native,
          title: title,
          initialRoute: Routes.SPLASH,
          getPages: AppPages.pages,
          theme: theme,
          darkTheme: darkThemeData,
          themeMode: theme.brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
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
