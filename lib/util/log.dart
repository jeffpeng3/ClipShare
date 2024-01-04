import 'package:flutter/cupertino.dart';
import 'package:logger/logger.dart';

class Log {
  static final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
    ),
  );
  static final _split="┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄";
  static toDb(String tag, dynamic) {
    var log = "$tag ${DateTime.now()}\n $dynamic";
  }

  static void debug(String tag, dynamic) {
    var log = "$tag ${DateTime.now()}\n$_split\n $dynamic \n$_split\n$tag ${DateTime.now()}";
    _logger.d(log);
    toDb(tag, dynamic);
  }

  static void trace(String tag, dynamic) {
    var log = "$tag ${DateTime.now()}\n$_split\n $dynamic \n$_split\n$tag ${DateTime.now()}";
    _logger.t(log);
    toDb(tag, dynamic);
  }

  static void info(String tag, dynamic) {
    var log = "$tag ${DateTime.now()}\n$_split\n $dynamic \n$_split\n$tag ${DateTime.now()}";
    _logger.i(log);
    toDb(tag, dynamic);
  }

  static void warn(String tag, dynamic) {
    var log = "$tag ${DateTime.now()}\n$_split\n $dynamic \n$_split\n$tag ${DateTime.now()}";
    _logger.w(log);
    toDb(tag, dynamic);
  }

  static void error(String tag, dynamic) {
    _logger.e("$tag ${DateTime.now()}\n $dynamic");
    toDb(tag, dynamic);
  }

  static void fatal(String tag, dynamic) {
    var log = "$tag ${DateTime.now()}\n$_split\n $dynamic \n$_split\n$tag ${DateTime.now()}";
    _logger.w(log);
    toDb(tag, dynamic);
  }
}
