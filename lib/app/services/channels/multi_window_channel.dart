import 'dart:convert';
import 'dart:ui';

import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:get/get.dart';

class MultiWindowMethod {
  MultiWindowMethod._private();

  static const getHistories = "getHistories";
  static const copy = "copy";
  static const notify = "notify";
  static const getCompatibleOnlineDevices = "getCompatibleOnlineDevices";
  static const syncFiles = "syncFiles";
  static const storeWindowPos = "storeWindowPos";
}

class MultiWindowChannelService extends GetxService {
  static const tag = "MultiWindowChannelService";

  ///获取历史数据
  Future getHistories(int targetWindowId, int fromId) {
    if (!PlatformExt.isDesktop) return Future(() => []);
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.getHistories,
      jsonEncode({"fromId": fromId}),
    );
  }

  ///通知主窗体复制
  Future copy(int targetWindowId, int historyId) {
    if (!PlatformExt.isDesktop) return Future(() => false);
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.copy,
      jsonEncode({"id": historyId}),
    );
  }

  ///通知子窗体数据变更
  Future notify(int targetWindowId) {
    if (!PlatformExt.isDesktop) return Future(() => false);
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.notify,
      "{}",
    );
  }

  ///获取当前在线的兼容版本设备列表
  Future getCompatibleOnlineDevices(int targetWindowId) {
    if (!PlatformExt.isDesktop) return Future(() => []);
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.getCompatibleOnlineDevices,
      "{}",
    );
  }

  ///发送待发送文件和设备列表
  Future syncFiles(
    int targetWindowId,
    List<Device> devices,
    List<String> files,
  ) {
    if (!PlatformExt.isDesktop) return Future.value();
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.syncFiles,
      jsonEncode({
        "devices": devices,
        "files": files,
      }),
    );
  }

  ///发送当前窗体的位置给主程序
  Future storeWindowPos(int targetWindowId, String type, Offset pos) {
    return DesktopMultiWindow.invokeMethod(
      targetWindowId,
      MultiWindowMethod.storeWindowPos,
      jsonEncode({
        "type": type,
        "pos": "${pos.dx}x${pos.dy}",
      }),
    );
  }
}
