import 'package:clipshare/app/modules/about_module/about_controller.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class AboutBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AboutController());
  }
}