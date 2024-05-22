import 'dart:io';
import 'dart:math';

import 'package:clipshare/channels/android_channel.dart';
import 'package:flutter/material.dart';

class Global {
  static void toast(String text) {
    AndroidChannel.toast(text);
  }

  static void notify(String content) {
    if (Platform.isAndroid) {
      AndroidChannel.sendNotify(content);
    }
  }

  static void snackBarSuc(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: Colors.lightBlue,
      ),
    );
  }

  static void snackBarErr(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: Colors.redAccent,
      ),
    );
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
                      Navigator.pop(context);
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
                            Navigator.pop(context);
                            onCancel?.call();
                          },
                          child: Text(cancelText),
                        ),
                      ),
                      Visibility(
                        visible: showOk,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
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
  }) {
    showDialog(
      context: context,
      barrierDismissible: dismissible,
      builder: (context) {
        var h = MediaQuery.of(context).size.height;
        return Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 350,
              maxHeight: min(h * 0.7, 350 * 1.618),
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
}
