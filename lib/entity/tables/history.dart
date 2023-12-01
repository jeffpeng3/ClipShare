import 'dart:ffi';

class History {
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
}
