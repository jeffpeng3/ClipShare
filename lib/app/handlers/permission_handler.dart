import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

abstract class AbstractPermissionHandler {
  static void showRequestDialog({
    required String title,
    required Widget content,
    required bool Function(BuildContext) onConfirm,
    void Function(BuildContext)? onClose,
    bool allowCloseInBlank = false,
    String closeText = "取消",
    String confirmText = "去授权",
  }) {
    showDialog(
      context: Get.context!,
      barrierDismissible: allowCloseInBlank,
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
        Global.showTipsDialog(
          context: ctx,
          title: "必要权限缺失",
          text: '请授予悬浮窗权限，否则无法后台读取剪贴板',
        );
      },
      onConfirm: (ctx) {
        final androidChannelService = Get.find<AndroidChannelService>();
        androidChannelService.androidChannel
            .invokeMethod<bool>("grantAlertWindowPermission")
            .then((res) async {
          if (await hasPermission()) return;
          Global.showTipsDialog(
            context: ctx,
            title: "必要权限缺失",
            text: '请授予悬浮窗权限，否则无法后台读取剪贴板',
          );
        });
        return true;
      },
    );
  }

  @override
  Future<bool> hasPermission() async {
    final androidChannelService = Get.find<AndroidChannelService>();
    var res = await androidChannelService.androidChannel
        .invokeMethod<bool>("checkAlertWindowPermission");
    if (res == null) return false;
    return res;
  }
}

///Shizuku权限处理请求
class ShizukuPermHandler extends AbstractPermissionHandler {
  @override
  void request() {
    final androidChannelService = Get.find<AndroidChannelService>();
    final appConfig = Get.find<ConfigService>();
    AbstractPermissionHandler.showRequestDialog(
      title: "Shizuku权限请求",
      content: const Text(
        '由于 Android 10 及以上版本的系统不允许后台读取剪贴板，需要依赖 Shizuku，否则只能被动接收剪贴板数据而不能自动同步',
      ),
      closeText: appConfig.ignoreShizuku ? "取消" : "不再提示",
      onClose: (ctx) {
        if (appConfig.ignoreShizuku) {
          return;
        }
        Global.showTipsDialog(
          context: ctx,
          text: "确认不再提示？",
          showCancel: true,
          onOk: () async {
            appConfig.setIgnoreShizuku();
            print("App.settings.ignoreShizuku ${appConfig.ignoreShizuku}");
          },
        );
      },
      onConfirm: (ctx) {
        androidChannelService.grantShizukuPermission(ctx);
        return true;
      },
    );
  }

  @override
  Future<bool> hasPermission() async {
    final androidChannelService = Get.find<AndroidChannelService>();
    var res = await androidChannelService.checkShizukuPermission();
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
        final androidChannelService = Get.find<AndroidChannelService>();
        androidChannelService.androidChannel
            .invokeMethod<bool>("grantNotification")
            .then((hasPerm) {
          //启动服务
          androidChannelService.androidChannel.invokeMethod("startService");
        });
        return true;
      },
    );
  }

  @override
  Future<bool> hasPermission() async {
    final androidChannelService = Get.find<AndroidChannelService>();
    var res = await androidChannelService.androidChannel
        .invokeMethod<bool>("checkNotification");
    if (res == null) return false;
    return res;
  }
}

///电池优化权限处理请求
class IgnoreBatteryHandler extends AbstractPermissionHandler {
  @override
  void request() {
    AbstractPermissionHandler.showRequestDialog(
      title: "电池优化",
      content: const Text(
        '取消电池优化以提高后台留存率',
      ),
      onConfirm: (ctx) {
        final androidChannelService = Get.find<AndroidChannelService>();
        androidChannelService.androidChannel
            .invokeMethod<bool>("requestIgnoreBattery");
        return true;
      },
    );
  }

  @override
  Future<bool> hasPermission() async {
    final androidChannelService = Get.find<AndroidChannelService>();
    var res = await androidChannelService.androidChannel
        .invokeMethod<bool>("checkIgnoreBattery");
    if (res == null) return false;
    return res;
  }
}
