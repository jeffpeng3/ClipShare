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

  static void showTipsDialog(
    BuildContext context,
    String text, [
    String title = "提示",
  ]) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(text),
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
  static void showDialogPage(BuildContext context,Widget widget){
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
