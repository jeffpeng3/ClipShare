import 'dart:io';

import 'package:clipshare/main.dart';
import 'package:clipshare/util/log.dart';

class CommonChannelMethod {
  CommonChannelMethod._private();
  static const getSelectedFiles = "getSelectedFiles";
}

class CommonChannel {
  CommonChannel._private();
  static const tag = "CommonChannel";

  /// 获取用户选择的文件（不支持桌面，当前仅支持windows)
  static Future<List<String>> getSelectedFiles() {
    if (!Platform.isWindows) return Future(() => List.empty());
    return App.commonChannel
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
