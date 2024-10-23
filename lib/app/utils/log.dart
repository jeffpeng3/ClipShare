import 'dart:io';

import 'package:clipshare/app/services/config_service.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:clipshare/app/utils/extension.dart';

class Log {
  Log._private();
  static Future _writeFuture = Future.value();
  static final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
    ),
  );

  static void debug(String tag, dynamic) {
    var log = "[$tag] ${DateTime.now().format()} | $dynamic";
    _logger.d(log);
    writeFiles("[debug] | $log");
  }

  static void trace(String tag, dynamic) {
    var log = "[$tag] ${DateTime.now().format()} | $dynamic";
    _logger.t(log);
    writeFiles("[trace] | $log");
  }

  static void info(String tag, dynamic) {
    var log = "[$tag] ${DateTime.now().format()} | $dynamic";
    _logger.i(log);
    writeFiles("[info] | $log");
  }

  static void warn(String tag, dynamic) {
    var log = "[$tag] ${DateTime.now().format()} | $dynamic";
    _logger.w(log);
    writeFiles("[warn] | $log");
  }

  static void fatal(String tag, dynamic) {
    var log = "[$tag] ${DateTime.now().format()} | $dynamic";
    _logger.w(log);
    writeFiles("[fatal] | $log");
  }

  static void error(String tag, dynamic) {
    var log = "[$tag] ${DateTime.now().format()} | $dynamic";
    _logger.e(log);
    writeFiles("[error] | $log");
  }

  static void writeFiles(String content) {
    final appConfig = Get.find<ConfigService>();
    try {
      if (!appConfig.enableLogsRecord) {
        return;
      }
    } catch (e) {
      return;
    }
    var dateStr = DateTime.now().toString().substring(0, 10);
    var filePath = "${appConfig.logsDirPath}/$dateStr.txt";
    Directory(appConfig.logsDirPath).createSync();
    var file = File(filePath);
    var f = file
        .writeAsString(content, mode: FileMode.writeOnlyAppend)
        .then((f) => f.writeAsString("\n", mode: FileMode.writeOnlyAppend));
    _writeFuture = _writeFuture.then((v) => f);
  }
}
