import 'package:clipshare/app/handlers/guide/battery_perm_guide.dart';
import 'package:clipshare/app/handlers/guide/finish_guide.dart';
import 'package:clipshare/app/handlers/guide/float_perm_guide.dart';
import 'package:clipshare/app/handlers/guide/notify_perm_guide.dart';
import 'package:clipshare/app/handlers/guide/shizuku_perm_guide.dart';
import 'package:clipshare/app/handlers/guide/storage_perm_guide.dart';
import 'package:clipshare/app/modules/user_guide_module/user_guide_controller.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class UserGuideBinding implements Bindings {
  final appConfig = Get.find<ConfigService>();

  @override
  void dependencies() {
    Get.lazyPut(
      () => UserGuideController(
        [
          FloatPermGuide(),
          StoragePermGuide(),
          if (appConfig.osVersion >= 10) ShizukuPermGuide(),
          NotifyPermGuide(),
          BatteryPermGuide(),
          FinishGuide()
        ],
      ),
    );
  }
}
