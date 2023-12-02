import 'dart:ffi';

class History implements Comparable {
  int? id;
  int? uuid;
  late int userId;
  late DateTime time;
  late String content;
  late String type;
  bool top = false;
  bool sync = false;
  late int size;

  History({
    this.id,
    this.uuid,
    required this.userId,
    required this.time,
    required this.content,
    required this.type,
    this.top = false,
    this.sync = false,
    required this.size,
  });

  @override
  int compareTo(other) {
    // 首先按照 top 属性排序
    if (top && !other.top) {
      return 1;
    } else if (!top && other.top) {
      return -1;
    } else {
      // 如果 top 属性相同，则按照 time 属性排序（时间较小的在前面）
      return time.compareTo(other.time);
    }
  }
}
