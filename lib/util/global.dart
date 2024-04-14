import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import '../main.dart';

class Global {
  static void toast(String text) {
    App.androidChannel.invokeMethod("toast", {"content": text});
  }

  static void notify(String content) {
    if (Platform.isAndroid) {
      App.androidChannel.invokeMethod("sendNotify", {"content": content});
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
    bool showCancel = false,
    bool showOk = true,
    void Function()? onOk,
    void Function()? onCancel,
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
        );
      },
    );
  }

  static void showDialogPage(BuildContext context, Widget widget) {
    showDialog(
      context: context,
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
            child: widget,
          ),
        );
      },
    );
  }
}
