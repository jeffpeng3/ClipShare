import 'package:clipshare/main.dart';
import 'package:clipshare/util/global.dart';
import 'package:flutter/cupertino.dart';

class AndroidChannelMethod {
  AndroidChannelMethod._private();

  static const onScreenOpened = "onScreenOpened";
  static const checkMustPermission = "checkMustPermission";
  static const notifyMediaScan = "notifyMediaScan";
  static const grantShizukuPermission = "grantShizukuPermission";
  static const checkShizukuPermission = "checkShizukuPermission";
  static const startService = "startService";
  static const showHistoryFloatWindow = "showHistoryFloatWindow";
  static const closeHistoryFloatWindow = "closeHistoryFloatWindow";
  static const lockHistoryFloatLoc = "lockHistoryFloatLoc";
  static const moveToBg = "moveToBg";
  static const toast = "toast";
  static const sendNotify = "sendNotify";
}

class AndroidChannel {
  AndroidChannel._private();

  /// 通知 Android 媒体库刷新
  static void notifyMediaScan(String path) {
    App.androidChannel.invokeMethod(AndroidChannelMethod.notifyMediaScan, {
      "imagePath": path,
    });
  }

  /// 授权Shizuku权限
  static void grantShizukuPermission(BuildContext ctx) {
    App.androidChannel
        .invokeMethod<bool>(AndroidChannelMethod.grantShizukuPermission)
        .then((res) {
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
    return App.androidChannel.invokeMethod<bool>(
      AndroidChannelMethod.checkShizukuPermission,
    );
  }

  /// 启动通知服务
  static void startForegroundService([bool restart = false]) {
    App.androidChannel.invokeMethod(
      AndroidChannelMethod.startService,
      {"restart": restart},
    );
  }

  /// 显示历史悬浮窗
  static void showHistoryFloatWindow() {
    App.androidChannel.invokeMethod(
      AndroidChannelMethod.showHistoryFloatWindow,
    );
  }

  /// 关闭历史悬浮窗
  static void closeHistoryFloatWindow() {
    App.androidChannel.invokeMethod(
      AndroidChannelMethod.closeHistoryFloatWindow,
    );
  }

  /// 锁定历史悬浮窗位置
  static void lockHistoryFloatLoc(dynamic data) {
    App.androidChannel.invokeMethod(
      AndroidChannelMethod.lockHistoryFloatLoc,
      data,
    );
  }

  /// 回到桌面
  static void moveToBg() {
    App.androidChannel.invokeMethod(
      AndroidChannelMethod.moveToBg,
    );
  }

  /// toast
  static void toast(String text) {
    App.androidChannel.invokeMethod(
      AndroidChannelMethod.toast,
      {"content": text},
    );
  }

  /// 发送通知
  static void sendNotify(String content) {
    App.androidChannel.invokeMethod(
      AndroidChannelMethod.sendNotify,
      {"content": content},
    );
  }
}
