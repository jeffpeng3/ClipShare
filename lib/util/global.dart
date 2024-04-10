import 'dart:io';

import 'package:flutter/material.dart';

import '../main.dart';

class Global {
  static void toast(String text) {
    App.androidChannel.invokeMethod("toast", {"content": text});
  }

  static void notify(String content) {
    if(Platform.isAndroid) {
      App.androidChannel.invokeMethod("sendNotify", {"content": content});
    }
  }

  static void snackBarSuc(BuildContext context,String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: Colors.lightBlue,
      ),
    );
  }

  static void snackBarErr(BuildContext context,String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}
