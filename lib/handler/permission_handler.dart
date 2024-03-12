import 'package:clipshare/main.dart';
import 'package:flutter/material.dart';

abstract class AbstractPermissionHandler {
  static void showRequestDialog({
    required String title,
    required Widget content,
    required bool Function(BuildContext) onConfirm,
    void Function(BuildContext)? onClose,
    String closeText = "取消",
    String confirmText = "去授权",
  }) {
    showDialog(
      context: App.context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: content,
          actions: [
            TextButton(
              onPressed: () {
                // 关闭弹窗
                Navigator.pop(context);
                onClose?.call(context);
              },
              child: Text(closeText),
            ),
            TextButton(
              onPressed: () {
                if (onConfirm.call(context)) {
                  // 关闭弹窗
                  Navigator.pop(context);
                }
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  static void showCloseDialog(String title, String content) {
    showDialog(
      context: App.context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("确定"),
            ),
          ],
        );
      },
    );
  }

  void request();

  Future<bool> hasPermission();
}

///悬浮窗权限处理请求
class FloatPermHandler extends AbstractPermissionHandler {
  @override
  void request() {
    AbstractPermissionHandler.showRequestDialog(
      title: "请求悬浮窗权限",
      content: const Text(
        '由于 Android 10 及以上版本的系统不允许后台读取剪贴板，当剪贴板发生变化时应用需要通过读取系统日志以及悬浮窗权限间接进行剪贴板读取。'
        '\n\n点击确定跳转页面授权悬浮窗权限',
      ),
      onClose: (ctx) {
        AbstractPermissionHandler.showCloseDialog(
          "必要权限缺失",
          '请授予悬浮窗权限，否则无法后台读取剪贴板',
        );
      },
      onConfirm: (ctx) {
        App.androidChannel
            .invokeMethod<bool>("grantAlertWindowPermission")
            .then((res) async {
          if (await hasPermission()) return;
          AbstractPermissionHandler.showCloseDialog(
            "必要权限缺失",
            '请授予悬浮窗权限，否则无法后台读取剪贴板',
          );
        });
        return true;
      },
    );
  }

  @override
  Future<bool> hasPermission() async {
    var res = await App.androidChannel
        .invokeMethod<bool>("checkAlertWindowPermission");
    if (res == null) return false;
    return res;
  }
}

///Shizuku权限处理请求
class ShizukuPermHandler extends AbstractPermissionHandler {
  @override
  void request() {
    AbstractPermissionHandler.showRequestDialog(
      title: "必要权限缺失",
      content: const Text(
        '请授权必要权限，由于 Android 10 及以上版本的系统不允许后台读取剪贴板，需要依赖 Shizuku ，否则只能被动接收剪贴板数据而不能发送',
      ),
      onClose: (ctx) {
        AbstractPermissionHandler.showCloseDialog(
          "必要权限缺失",
          '请授予 Shizuku 权限，否则无法后台读取剪贴板',
        );
      },
      onConfirm: (ctx) {
        App.androidChannel
            .invokeMethod<bool>("grantShizukuPermission")
            .then((res) {
          if (res == true) return;
          AbstractPermissionHandler.showCloseDialog(
            "必要权限缺失",
            '请授予 Shizuku 权限，否则无法后台读取剪贴板',
          );
        });
        return true;
      },
    );
  }

  @override
  Future<bool> hasPermission() async {
    var res =
        await App.androidChannel.invokeMethod<bool>("checkShizukuPermission");
    if (res == null) return false;
    return res;
  }
}

///通知权限处理请求
class NotifyPermHandler extends AbstractPermissionHandler {
  @override
  void request() {
    AbstractPermissionHandler.showRequestDialog(
      title: "请求通知权限",
      content: const Text(
        '用于发送系统通知',
      ),
      onConfirm: (ctx) {
        App.androidChannel.invokeMethod<bool>("grantNotification");
        return true;
      },
    );
  }

  @override
  Future<bool> hasPermission() async {
    var res = await App.androidChannel.invokeMethod<bool>("checkNotification");
    if (res == null) return false;
    return res;
  }
}

///通知权限处理请求
class IgnoreBatteryHandler extends AbstractPermissionHandler {
  @override
  void request() {
    AbstractPermissionHandler.showRequestDialog(
      title: "电池优化",
      content: const Text(
        '取消电池优化以提高后台留存率',
      ),
      onConfirm: (ctx) {
        App.androidChannel.invokeMethod<bool>("requestIgnoreBattery");
        return true;
      },
    );
  }

  @override
  Future<bool> hasPermission() async {
    var res = await App.androidChannel.invokeMethod<bool>("checkIgnoreBattery");
    if (res == null) return false;
    return res;
  }
}
