import 'package:clipboard_listener/clipboard_manager.dart';
import 'package:clipboard_listener/enums.dart';
import 'package:clipshare/app/listeners/history_data_listener.dart';
import 'package:clipshare/app/modules/settings_module/settings_controller.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:get/get.dart';

class ClipboardService extends GetxService with ClipboardListener {
  final appConfig = Get.find<ConfigService>();
  final settingsController = Get.find<SettingsController>();

  Future<ClipboardService> init() async {
    clipboardManager.addListener(this);
    return this;
  }

  @override
  void onClipboardChanged(ClipboardContentType type, String content) {
    final contentType = HistoryContentType.parse(type.name);
    HistoryDataListener.inst.onChanged(contentType, content);
  }

  @override
  Future<void> onPermissionStatusChanged(EnvironmentType environment, bool isGranted) async {
    final settingsController = Get.find<SettingsController>();
    if (isGranted &&
        environment != EnvironmentType.none &&
        environment != EnvironmentType.androidPre10) {
      await clipboardManager.startListening(startEnv: environment);
    }
    settingsController.checkPermissions();
  }

  @override
  void onClose() {
    clipboardManager.removeListener(this);
    super.onClose();
  }
}
