import 'package:clipshare/app/utils/log.dart';

enum WeekDay {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  int get value {
    switch (this) {
      case WeekDay.monday:
        return 1;
      case WeekDay.tuesday:
        return 2;
      case WeekDay.wednesday:
        return 3;
      case WeekDay.thursday:
        return 4;
      case WeekDay.friday:
        return 5;
      case WeekDay.saturday:
        return 6;
      case WeekDay.sunday:
        return 0;
    }
  }

  String get label {
    switch (this) {
      case WeekDay.monday:
        return "周一";
      case WeekDay.tuesday:
        return "周二";
      case WeekDay.wednesday:
        return "周三";
      case WeekDay.thursday:
        return "周四";
      case WeekDay.friday:
        return "周五";
      case WeekDay.saturday:
        return "周六";
      case WeekDay.sunday:
        return "周日";
    }
  }

  static WeekDay parse(int value) {
    return WeekDay.values.firstWhere(
      (e) => e.value == value,
      orElse: () {
        Log.debug("WeekDay", "key '$value' unknown");
        throw Exception("Unknown WeekDay value: $value");
      },
    );
  }
}
