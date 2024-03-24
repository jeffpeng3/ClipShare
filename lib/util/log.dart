// import 'package:clipshare/util/constants.dart';
import 'package:logger/logger.dart';

class Log {
  static final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
    ),
  );

  static const _split = '''
┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
  ''';

  // static toDb(String module, Option option, dynamic data) {}

  static void debug(String tag, dynamic) {
    var log = "$tag ${DateTime.now()}\n"
        "$_split\n "
        "$dynamic \n"
        "$_split\n"
        "$tag ${DateTime.now()}";
    _logger.d(log);
  }

  static void trace(String tag, dynamic) {
    var log = "$tag ${DateTime.now()}\n"
        "$_split\n "
        "$dynamic \n"
        "$_split\n"
        "$tag ${DateTime.now()}";
    _logger.t(log);
  }

  static void info(String tag, dynamic) {
    var log = "$tag ${DateTime.now()}\n"
        "$_split\n "
        "$dynamic \n"
        "$_split\n"
        "$tag ${DateTime.now()}";
    _logger.i(log);
  }

  static void warn(String tag, dynamic) {
    var log = "$tag ${DateTime.now()}\n"
        "$_split\n "
        "$dynamic \n"
        "$_split\n"
        "$tag ${DateTime.now()}";
    _logger.w(log);
  }

  static void fatal(String tag, dynamic) {
    var log = "$tag ${DateTime.now()}\n"
        "$_split\n "
        "$dynamic \n"
        "$_split\n"
        "$tag ${DateTime.now()}";
    _logger.w(log);
  }

  static void error(String tag, dynamic) {
    _logger.e("$tag ${DateTime.now()}\n $dynamic");
  }
}
