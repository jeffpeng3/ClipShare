import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../main.dart';

class Global {
  static void toast(String text) {
    App.androidChannel.invokeMethod("toast", {"content": text});
  }


  static void notify(String content) {
    App.androidChannel.invokeMethod("sendNotify", {"content": content});
  }

  static void snackBarSuc(String text) {
    ScaffoldMessenger.of(App.context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: Colors.lightBlue,
    ));
  }

  static void snackBarErr(String text) {
    ScaffoldMessenger.of(App.context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: Colors.redAccent,
    ));
  }
}
