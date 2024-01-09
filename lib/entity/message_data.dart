import 'dart:convert';

import '../util/constants.dart';
import 'dev_info.dart';

class MessageData {
  int userId;
  DevInfo send;
  DevInfo? recv;
  MsgType key;
  Map<String, dynamic> data;

  MessageData(
      {required this.userId,
      required this.send,
      required this.key,
      required this.data,
      this.recv});

  static MessageData fromJson(Map<String, dynamic> map) {
    int userId = map["userId"];
    DevInfo devInfo = DevInfo.fromJson(map["send"]);
    DevInfo? recv = map["recv"] != null ? DevInfo.fromJson(map["recv"]) : null;
    MsgType key = MsgType.getValue(map["key"]);
    Map<String, dynamic> data = map["data"];
    return MessageData(
        userId: userId, send: devInfo, key: key, data: data, recv: recv);
  }

  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      "send": send.toJson(),
      "recv": recv?.toJson(),
      "key": key.name,
      "data": data,
    };
  }

  @override
  String toString() {
    return toJsonStr();
  }

  String toJsonStr() {
    return jsonEncode(toJson());
  }
}
