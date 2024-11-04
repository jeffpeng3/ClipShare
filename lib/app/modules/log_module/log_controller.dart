import 'dart:io';

import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/extensions/file_extension.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class LogController extends GetxController {
  final logs = <File>[].obs;
  final init = false.obs;
  final appConfig = Get.find<ConfigService>();

  @override
  void onInit() {
    super.onInit();
    loadLogFileList();
  }

  void loadLogFileList() {
    final directory = Directory(appConfig.logsDirPath);
    logs.value = [];
    if (!directory.existsSync()) {
      init.value = true;
      return;
    }
    List<FileSystemEntity> entities = directory.listSync(recursive: false);
    for (var entity in entities) {
      if (entity is File) {
        logs.add(entity);
      }
    }
    logs.sort(((a, b) => b.fileName.compareTo(a.fileName)));
    init.value = true;
  }
}
