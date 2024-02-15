import 'dart:convert';

import 'package:floor/floor.dart';

@Entity(indices: [
  Index(value: ['tagName', "hisId"], unique: true)
])
class HistoryTag {
  ///主键 id
  @PrimaryKey(autoGenerate: true)
  int id;

  ///标签名称
  late String tagName;

  /// 历史 id
  late int hisId;

  HistoryTag(
    this.id,
    this.tagName,
    this.hisId,
  );

  HistoryTag.empty({this.id = 0, this.tagName = "", this.hisId = 0});

  static HistoryTag fromJson(Map<String, dynamic> map) {
    return HistoryTag(map["id"], map["tagName"], map["hisId"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "tagName": tagName,
      "hisId": hisId,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
