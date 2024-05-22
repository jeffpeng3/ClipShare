import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';

class MultiWindowMethod {
  MultiWindowMethod._private();

  static const getHistories = "getHistories";
  static const copy = "copy";
  static const notify = "notify";
}

class MultiWindowChannel {
  MultiWindowChannel._private();

  static Future getHistories(int targetWindowId, int fromId) {
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.getHistories,
      jsonEncode({"fromId": fromId}),
    );
  }

  static Future copy(int targetWindowId, int historyId) {
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.copy,
      jsonEncode({"id": historyId}),
    );
  }

  static Future notify(int targetWindowId) {
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.notify,
      "{}",
    );
  }
}
