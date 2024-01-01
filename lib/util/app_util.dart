import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../main.dart';

class AppUtil {
  static void toast(String text, [int milliseconds = 2000]) {
    var widget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: const Color.fromRGBO(240, 240, 240, 0.75),
      ),
      child: Text(text),
    );
    customToast(App.context, widget);
  }

  static void customToast(BuildContext context, Widget widget,
      [int milliseconds = 2000]) {
    App.toast.init(context);
    App.toast.showToast(
      child: widget,
      gravity: ToastGravity.BOTTOM,
      toastDuration: Duration(milliseconds: milliseconds),
    );
  }

  static void notify(String content) {}

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
