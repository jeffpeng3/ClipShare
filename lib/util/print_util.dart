import 'package:flutter/cupertino.dart';

class PrintUtil {
  static void debug(String tag, Object? object) {
    debugPrint("$tag : $object");
  }

  static void print(Object? object) {
    debugPrint("default : $object");
  }
}
