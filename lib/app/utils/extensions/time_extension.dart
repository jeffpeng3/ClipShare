import 'package:intl/intl.dart' as intl;

extension DateTimeExt on DateTime {
  String format([String format = "yyyy-MM-dd HH:mm:ss"]) {
    return intl.DateFormat(format).format(this);
  }

  String get simpleStr {
    String time = "";
    DateTime now = DateTime.now();
    Duration difference = now.difference(this);

    if (difference.inMinutes < 1) {
      time = "刚刚";
    } else if (difference.inHours < 1) {
      int minutes = difference.inMinutes;
      time = "$minutes分钟前";
    } else if (difference.inHours < 24) {
      int hours = difference.inHours;
      time = "$hours小时前";
    } else {
      time = toString().substring(0, 19); // 使用默认的日期时间格式
    }
    return time;
  }
}
