import 'dart:io';

import 'package:clipshare/main.dart';
import 'package:clipshare/util/log.dart';

class CommonChannel {
  static const tag = "CommonChannel";

  /// 获取用户选择的文件（不支持桌面，当前仅支持windows)
  static void getSelectedFiles() {
    if (!Platform.isWindows) return;
    App.commonChannel.invokeMethod("getSelectedFiles").then(
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
          return;
        }
        Log.info(tag, "getSelectedFiles list: $list");
      },
    );
  }
}
