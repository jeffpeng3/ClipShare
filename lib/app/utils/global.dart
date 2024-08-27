import 'dart:io';
import 'dart:math';

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

  static void showSnackBarSuc(BuildContext context, String text) {
    showSnackBar(context, text, Colors.lightBlue);
  }

  static void showSnackBar(BuildContext context, String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: color,
      ),
    );
  }

  static void showSnackBarErr(BuildContext context, String text) {
    showSnackBar(context, text, Colors.redAccent);
  }

  static void showSnackBarWarn(BuildContext context, String text) {
    showSnackBar(context, text, Colors.orange);
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

  static void showDialogPage({
    required BuildContext context,
    required Widget child,
    dismissible = true,
    double? maxWidth = 350,
  }) {
    showDialog(
      context: context,
      barrierDismissible: dismissible,
      builder: (context) {
        var h = MediaQuery.of(context).size.height;
        return Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: maxWidth ?? double.infinity,
              maxHeight: min(h * 0.7, (maxWidth ?? 350) * 1.618),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: child,
          ),
        );
      },
    );
  }

  static void showLoadingDialog({
    required BuildContext context,
    bool dismissible = false,
    bool showCancel = false,
    String? loadingText,
  }) {
    showDialog(
      context: context,
      barrierDismissible: dismissible,
      builder: (context) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AlertDialog(
              content: SizedBox(
                height: 80,
                child: Loading(
                  width: 32,
                  description: loadingText != null ? Text(loadingText) : null,
                ),
              ),
            ),
            Visibility(
              visible: showCancel,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Get.back();
                    },
                    child: const Text("取消"),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
