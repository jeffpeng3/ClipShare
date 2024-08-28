import '../../app/modules/authentication_module/authentication_page.dart';
import '../../app/modules/authentication_module/authentication_bindings.dart';
import 'package:clipshare/app/modules/home_module/home_page.dart';
import 'package:clipshare/app/widgets/pages/welcome_page.dart';
import 'package:get/get.dart';

import '../../app/modules/device_module/device_bindings.dart';
import '../../app/modules/device_module/device_page.dart';
import '../../app/modules/history_module/history_bindings.dart';
import '../../app/modules/history_module/history_page.dart';
import '../../app/modules/home_module/home_bindings.dart';
import '../../app/modules/search_module/search_bindings.dart';
import '../../app/modules/search_module/search_page.dart';
import '../../app/modules/settings_module/settings_bindings.dart';
import '../../app/modules/settings_module/settings_page.dart';
import '../../app/modules/splash_module/splash_bindings.dart';
import '../../app/modules/splash_module/splash_page.dart';

part './app_routes.dart';
/**
 * GetX Generator - fb.com/htngu.99
 * */

abstract class AppPages {
  static final pages = [
    GetPage(
      name: Routes.splash,
      page: () => SplashPage(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: Routes.welcome,
      page: () => WelcomePage(),
    ),
    GetPage(
      name: Routes.home,
      page: () => HomePage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.HISTORY,
      page: () => HistoryPage(),
      binding: HistoryBinding(),
    ),
    GetPage(
      name: Routes.SEARCH,
      page: () => SearchPage(),
      binding: SearchBinding(),
    ),
    GetPage(
      name: Routes.DEVICE,
      page: () => DevicePage(),
      binding: DeviceBinding(),
    ),
    GetPage(
      name: Routes.SETTINGS,
      page: () => SettingsPage(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: Routes.AUTHENTICATION,
      page: () => AuthenticationPage(),
      binding: AuthenticationBinding(),
    ),
  ];
}
