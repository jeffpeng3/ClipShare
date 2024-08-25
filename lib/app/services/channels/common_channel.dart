import 'dart:io';

import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class CommonChannelMethod {
  CommonChannelMethod._private();

  static const getSelectedFiles = "getSelectedFiles";
}

class CommonChannelService extends GetxService {
  static const tag = "CommonChannelService";

  late final MethodChannel commonChannel;

  CommonChannelService init() {
    final appConfig = Get.find<ConfigService>();
    commonChannel = appConfig.commonChannel;
    return this;
  }

  /// 获取用户选择的文件（不支持桌面，当前仅支持windows)
  Future<List<String>> getSelectedFiles() {
    if (!Platform.isWindows) return Future(() => List.empty());
    return commonChannel
        .invokeMethod(CommonChannelMethod.getSelectedFiles)
        .then(
      (res) {
        bool succeeded = res["succeeded"] == 1;
        String listStr = res["list"];
        List<String> list = listStr
            .split(";")
            .where(
              (path) => path.trim().isNotEmpty,
            )
            .toList();
        if (!succeeded) {
          Log.error(tag, "getSelectedFiles failed");
          return Future(() => List.empty());
        }
        Log.info(tag, "getSelectedFiles list: $list");
        return list;
      },
    );
  }
}
