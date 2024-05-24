import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';

class MultiWindowMethod {
  MultiWindowMethod._private();

  static const getHistories = "getHistories";
  static const copy = "copy";
  static const notify = "notify";
  static const getCompatibleOnlineDevices = "getCompatibleOnlineDevices";
  static const syncFiles = "syncFiles";
}

class MultiWindowTag {
  MultiWindowTag._private();

  static const history = "history";
  static const devices = "devices";
}

class MultiWindowChannel {
  MultiWindowChannel._private();

  ///获取历史数据
  static Future getHistories(int targetWindowId, int fromId) {
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.getHistories,
      jsonEncode({"fromId": fromId}),
    );
  }

  ///通知主窗体复制
  static Future copy(int targetWindowId, int historyId) {
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.copy,
      jsonEncode({"id": historyId}),
    );
  }

  ///通知子窗体数据变更
  static Future notify(int targetWindowId) {
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.notify,
      "{}",
    );
  }

  ///获取当前在线的兼容版本设备列表
  static Future getCompatibleOnlineDevices(int targetWindowId) {
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.getCompatibleOnlineDevices,
      "{}",
    );
  }

  ///发送待发送文件和设备列表
  static Future syncFiles(
    int targetWindowId,
    List<String> devIds,
    List<String> files,
  ) {
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.syncFiles,
      jsonEncode({
        "devIds": devIds,
        "files": files,
      }),
    );
  }
}
