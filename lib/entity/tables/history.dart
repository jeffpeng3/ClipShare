import 'package:floor/floor.dart';

@entity
class History implements Comparable {
  @PrimaryKey(autoGenerate: true)
  ///本地id
  late int id;

  ///用户id（uuid）
  late String uid;

  ///时间
  late String time;

  ///剪贴板内容
  late String content;

  ///内容类型
  late String type;

  ///设备id
  String devId;

  ///是否置顶
  bool top = false;

  ///是否同步
  bool sync = false;

  ///内容大小、长度
  late int size;

  History({
    required this.id,
    required this.uid,
    required this.time,
    required this.content,
    required this.type,
    required this.devId,
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
