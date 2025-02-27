import 'package:clipshare/app/modules/data_clean_module/clean_data_controller.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class CleanDataBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CleanDataController());
  }
}