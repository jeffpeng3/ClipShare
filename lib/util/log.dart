
import 'dart:io';

import 'package:clipshare/main.dart';
import 'package:logger/logger.dart';

class Log {
  static Future _writeFuture = Future.value();
  static final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
    ),
  );

  static const _split = '''
┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
  ''';

  static void debug(String tag, dynamic) {
    var log = "$tag ${DateTime.now()} ↓↓↓↓↓ \n"
        "$_split\n "
        "$dynamic \n"
        "$_split\n"
        "$tag ${DateTime.now()}";
    _logger.d(log);
    writeFiles(log);
  }

  static void trace(String tag, dynamic) {
    var log = "$tag ${DateTime.now()} ↓↓↓↓↓ \n"
        "$_split\n "
        "$dynamic \n"
        "$_split\n"
        "$tag ${DateTime.now()}";
    _logger.t(log);
    writeFiles(log);
  }

  static void info(String tag, dynamic) {
    var log = "$tag ${DateTime.now()} ↓↓↓↓↓ \n"
        "$_split\n "
        "$dynamic \n"
        "$_split\n"
        "$tag ${DateTime.now()}";
    _logger.i(log);
    writeFiles(log);
  }

  static void warn(String tag, dynamic) {
    var log = "$tag ${DateTime.now()} ↓↓↓↓↓ \n"
        "$_split\n "
        "$dynamic \n"
        "$_split\n"
        "$tag ${DateTime.now()}";
    _logger.w(log);
    writeFiles(log);
  }

  static void fatal(String tag, dynamic) {
    var log = "$tag ${DateTime.now()} ↓↓↓↓↓ \n"
        "$_split\n "
        "$dynamic \n"
        "$_split\n"
        "$tag ${DateTime.now()}";
    _logger.w(log);
    writeFiles(log);
  }

  static void error(String tag, dynamic) {
    var content = "$tag ${DateTime.now()} ↓↓↓↓↓ \n $dynamic";
    _logger.e(content);
    writeFiles(content);
  }

  static void writeFiles(String content) {
    if (!App.settings.enableLogsRecord) {
      return;
    }
    content = "${content.replaceAll(_split, "----")}\n";
    var dateStr = DateTime.now().toString().substring(0, 10);
    var filePath = "${App.logsDirPath}/$dateStr.txt";
    Directory(App.logsDirPath).createSync();
    var file = File(filePath);
    var f = file.writeAsString(content, mode: FileMode.writeOnlyAppend);
    _writeFuture = _writeFuture.then((v) => f);
  }
}
