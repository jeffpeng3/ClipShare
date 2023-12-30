import 'package:flutter/cupertino.dart';

class PrintUtil {
  static void debug(String tag, Object? object) {
    debugPrint("${DateTime.now()} $tag : $object");
  }

  static void print(Object? object) {
    debugPrint("${DateTime.now()} default : $object");
  }
}
