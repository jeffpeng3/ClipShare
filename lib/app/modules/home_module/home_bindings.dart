import 'package:clipshare/app/modules/history_module/history_controller.dart';
import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/modules/search_module/search_controller.dart';
import 'package:clipshare/app/modules/settings_module/settings_controller.dart';
import 'package:clipshare/app/modules/statistics_module/statistics_controller.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class HomeBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(HomeController(), permanent: true);
    Get.put(HistoryController(), permanent: true);
    Get.put(SearchController(), permanent: true);
    Get.put(SettingsController(), permanent: true);
    Get.put(StatisticsController(), permanent: true);
  }
}
