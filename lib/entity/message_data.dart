import 'dart:convert';

import 'package:clipshare/entity/tables/history.dart';

import '../util/constants.dart';
import 'dev_info.dart';

class MessageData {
  String userId;
  DevInfo send;
  DevInfo? recv;
  MsgKey key;
  Map<String, dynamic> data;

  MessageData(
      {required this.userId,
      required this.send,
      required this.key,
      required this.data,
      this.recv});

  static MessageData fromJson(Map<String, dynamic> map) {
    String userId = map["userId"];
    DevInfo devInfo = DevInfo.fromJson(map["send"]);
    DevInfo? recv = map["recv"] != null ? DevInfo.fromJson(map["recv"]) : null;
    MsgKey key = MsgKey.getValue(map["key"]);
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
}
