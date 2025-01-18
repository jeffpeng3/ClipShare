import 'dart:io';

import 'package:clipboard_listener/clipboard_manager.dart';
import 'package:clipboard_listener/enums.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class AndroidChannelMethod {
  AndroidChannelMethod._private();

  static const onScreenOpened = "onScreenOpened";
  static const onScreenClosed = "onScreenClosed";
  static const notifyMediaScan = "notifyMediaScan";
  static const showHistoryFloatWindow = "showHistoryFloatWindow";
  static const closeHistoryFloatWindow = "closeHistoryFloatWindow";
  static const lockHistoryFloatLoc = "lockHistoryFloatLoc";
  static const moveToBg = "moveToBg";
  static const toast = "toast";
  static const sendNotify = "sendNotify";
  static const copyFileFromUri = "copyFileFromUri";
  static const startSmsListen = "startSmsListen";
  static const stopSmsListen = "stopSmsListen";
  static const onSmsChanged = "onSmsChanged";
  static const showOnRecentTasks = "showOnRecentTasks";
}

class AndroidChannelService extends GetxService {
  late final MethodChannel androidChannel;
  final appConfig = Get.find<ConfigService>();

  AndroidChannelService init() {
    androidChannel = appConfig.androidChannel;
    if (Platform.isAndroid) {
      if (appConfig.showHistoryFloat) {
        showHistoryFloatWindow();
      }
      lockHistoryFloatLoc(
        {"loc": appConfig.lockHistoryFloatLoc},
      );
    }
    return this;
  }

  /// 通知 Android 媒体库刷新
  void notifyMediaScan(String path) {
    if (!Platform.isAndroid) return;
    androidChannel.invokeMethod(AndroidChannelMethod.notifyMediaScan, {
      "imagePath": path,
    });
  }

  /// 授权Shizuku权限
  Future<void> grantShizukuPermission(BuildContext ctx) async {
    if (!Platform.isAndroid) return;
    await clipboardManager.requestPermission(EnvironmentType.shizuku);
  }

  /// 检查 Shizuku权限
  Future<bool?> checkShizukuPermission() {
    if (!Platform.isAndroid) return Future(() => false);
    return clipboardManager.checkPermission(EnvironmentType.shizuku);
  }

  /// 显示历史悬浮窗
  void showHistoryFloatWindow() {
    if (!Platform.isAndroid) return;
    androidChannel.invokeMethod(
      AndroidChannelMethod.showHistoryFloatWindow,
    );
  }

  /// 关闭历史悬浮窗
  void closeHistoryFloatWindow() {
    if (!Platform.isAndroid) return;
    androidChannel.invokeMethod(
      AndroidChannelMethod.closeHistoryFloatWindow,
    );
  }

  /// 锁定历史悬浮窗位置
  void lockHistoryFloatLoc(dynamic data) {
    if (!Platform.isAndroid) return;
    androidChannel.invokeMethod(
      AndroidChannelMethod.lockHistoryFloatLoc,
      data,
    );
  }

  /// 回到桌面
  void moveToBg() {
    if (!Platform.isAndroid) return;
    androidChannel.invokeMethod(
      AndroidChannelMethod.moveToBg,
    );
  }

  /// toast
  void toast(String text) {
    if (!Platform.isAndroid) return;
    androidChannel.invokeMethod(
      AndroidChannelMethod.toast,
      {"content": text},
    );
  }

  /// 发送通知
  void sendNotify(String content) {
    if (!Platform.isAndroid) return;
    androidChannel.invokeMethod(
      AndroidChannelMethod.sendNotify,
      {"content": content},
    );
  }

  ///复制content文件到指定路径
  Future<String?> copyFileFromUri(String content, String savedPath) {
    if (!Platform.isAndroid) return Future(() => null);
    return androidChannel.invokeMethod<String?>(
      AndroidChannelMethod.copyFileFromUri,
      {
        "content": content,
        "savedPath": savedPath,
      },
    );
  }

  ///开启短信监听
  Future<void> startSmsListen() {
    if (!Platform.isAndroid) return Future(() => null);
    return androidChannel.invokeMethod<String?>(
      AndroidChannelMethod.startSmsListen,
    );
  }

  ///关闭短信监听
  Future<void> stopSmsListen() {
    if (!Platform.isAndroid) return Future(() => null);
    return androidChannel.invokeMethod<String?>(
      AndroidChannelMethod.stopSmsListen,
    );
  }

  Future<bool> showOnRecentTasks(bool show) {
    if (!Platform.isAndroid) return Future.value(false);
    return androidChannel.invokeMethod<bool?>(
      AndroidChannelMethod.showOnRecentTasks,
      {
        "show": show,
      },
    ).then((v) => v ?? false);
  }
}
