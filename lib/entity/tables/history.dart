import 'dart:convert';

import 'package:floor/floor.dart';

@entity
class History implements Comparable {
  @PrimaryKey(autoGenerate: true)

  ///本地id
  int id;

  ///用户id（uuid）
  int uid;

  ///时间
  String time;

  ///剪贴板内容
  String content;

  ///内容类型
  String type;

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

  History.empty({
    this.id = 0,
    this.uid = 0,
    this.time = "",
    this.content = "",
    this.type = "",
    this.devId = "",
    this.top = false,
    this.sync = false,
    this.size = 0,
  });

  static History fromJson(map) {
    var id = map["id"];
    var uid = map["uid"];
    var time = map["time"];
    var content = map["content"];
    var type = map["type"];
    var devId = map["devId"];
    var top = map["top"];
    var sync = map["sync"];
    var size = map["size"];
    return History(
      id: id,
      uid: uid,
      time: time,
      content: content,
      type: type,
      devId: devId,
      size: size,
      top: top,
      sync: sync,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "uid": uid,
      "time": time,
      "content": content,
      "type": type,
      "devId": devId,
      "top": top,
      "sync": sync,
      "size": size,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
