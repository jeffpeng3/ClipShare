import 'package:clipshare/main.dart';
import 'package:clipshare/util/global.dart';
import 'package:flutter/cupertino.dart';

class AndroidChannel {
  /// 通知 Android 媒体库刷新
  static void notifyMediaScan(String path) {
    App.androidChannel.invokeMethod("notifyMediaScan", {
      "imagePath": path,
    });
  }

  /// 授权Shizuku权限
  static void grantShizukuPermission(BuildContext ctx) {
    App.androidChannel.invokeMethod<bool>("grantShizukuPermission").then((res) {
      if (res == true) {
        startForegroundService();
        return;
      }
      if (App.settings.ignoreShizuku) return;
      Global.showTipsDialog(
        context: ctx,
        title: "权限缺失",
        text: '请授予 Shizuku 权限，否则无法后台读取剪贴板',
      );
    });
  }

  /// 检查 Shizuku权限
  static Future<bool?> checkShizukuPermission() {
    return App.androidChannel.invokeMethod<bool>("checkShizukuPermission");
  }

  /// 启动通知服务
  static void startForegroundService([bool restart = false]) {
    App.androidChannel.invokeMethod("startService", {"restart": restart});
  }
}
