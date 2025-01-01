import 'dart:io';

import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Global {
  Global._private();

  static void toast(String text) {
    final androidChannelService = Get.find<AndroidChannelService>();
    androidChannelService.toast(text);
  }

  static void notify(String content) {
    if (Platform.isAndroid) {
      final androidChannelService = Get.find<AndroidChannelService>();
      androidChannelService.sendNotify(content);
    }
  }

  static void showSnackBar(
    BuildContext? context,
    ScaffoldMessengerState? scaffoldMessengerState,
    String text,
    Color color,
  ) {
    assert(context != null || scaffoldMessengerState != null);
    final snackbar = SnackBar(
      content: Text(text),
      backgroundColor: color,
    );
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(snackbar);
    } else {
      scaffoldMessengerState!.showSnackBar(snackbar);
    }
  }

  static void showSnackBarSuc({
    BuildContext? context,
    ScaffoldMessengerState? scaffoldMessengerState,
    required String text,
  }) {
    showSnackBar(context, scaffoldMessengerState, text, Colors.lightBlue);
  }

  static void showSnackBarErr({
    BuildContext? context,
    ScaffoldMessengerState? scaffoldMessengerState,
    required String text,
  }) {
    showSnackBar(context, scaffoldMessengerState, text, Colors.redAccent);
  }

  static void showSnackBarWarn({
    BuildContext? context,
    ScaffoldMessengerState? scaffoldMessengerState,
    required String text,
  }) {
    showSnackBar(context, scaffoldMessengerState, text, Colors.orange);
  }

  static void showTipsDialog({
    required BuildContext context,
    required String text,
    String title = "提示",
    String okText = "确定",
    String cancelText = "取消",
    String neutralText = "中立按钮",
    bool showCancel = false,
    bool showOk = true,
    bool showNeutral = false,
    void Function()? onOk,
    void Function()? onCancel,
    void Function()? onNeutral,
    bool autoDismiss = true,
  }) {
    showDialog(
      context: context,
      barrierDismissible: autoDismiss,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(text),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Visibility(
                  visible: showNeutral,
                  child: TextButton(
                    onPressed: () {
                      if (autoDismiss) {
                        Get.back();
                      }
                      onNeutral?.call();
                    },
                    child: Text(neutralText),
                  ),
                ),
                IntrinsicWidth(
                  child: Row(
                    children: [
                      Visibility(
                        visible: showCancel,
                        child: TextButton(
                          onPressed: () {
                            if (autoDismiss) {
                              Get.back();
                            }
                            onCancel?.call();
                          },
                          child: Text(cancelText),
                        ),
                      ),
                      Visibility(
                        visible: showOk,
                        child: TextButton(
                          onPressed: () {
                            if (autoDismiss) {
                              Get.back();
                            }
                            onOk?.call();
                          },
                          child: Text(okText),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  static void showLoadingDialog({
    required BuildContext context,
    bool dismissible = false,
    bool showCancel = false,
    void Function()? onCancel,
    String? loadingText,
  }) {
    showDialog(
      context: context,
      barrierDismissible: dismissible,
      builder: (context) {
        return PopScope(
          canPop: dismissible,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AlertDialog(
                content: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 80,
                        child: Loading(
                          width: 32,
                          description:
                              loadingText != null ? Text(loadingText) : null,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Visibility(
                        visible: showCancel,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                Get.back();
                                onCancel?.call();
                              },
                              child: const Text("取消"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
