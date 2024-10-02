import 'package:clipboard_listener/clipboard_manager.dart';
import 'package:clipboard_listener/enums.dart';
import 'package:clipshare/app/listeners/clipboard_listener.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:get/get.dart';

class ClipboardService extends GetxService with ClipboardListener {
  final appConfig = Get.find<ConfigService>();

  Future<ClipboardService> init() async {
    clipboardManager.addListener(this);
    return this;
  }

  @override
  void onClipboardChanged(ClipboardContentType type, String content) {
    final contentType = HistoryContentType.parse(type.name);
    print("type $type, content $content");
    HistoryDataListener.inst.onChanged(contentType, content);
  }

  @override
  void onPermissionStatusChanged(EnvironmentType environment, bool isGranted) {
    print("environment $environment, isGranted $isGranted");
    super.onPermissionStatusChanged(environment, isGranted);
    switch (environment) {
      case EnvironmentType.shizuku:
        if (isGranted) {
          clipboardManager.startListening();
          return;
        } else {
          if (appConfig.ignoreShizuku) return;
          Global.showTipsDialog(
            context: Get.context!,
            title: "权限缺失",
            text: '请授予 Shizuku 权限，否则无法后台读取剪贴板',
          );
        }
        break;
      case EnvironmentType.root:
        break;
      default:
    }
  }

  @override
  void onClose() {
    super.onClose();
    clipboardManager.removeListener(this);
  }
}
