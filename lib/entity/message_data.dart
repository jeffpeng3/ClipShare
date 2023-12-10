import 'package:clipshare/entity/tables/history.dart';

import 'dev_info.dart';

class MessageData {
  String userId;
  DevInfo devInfo;
  History history;

  MessageData(this.userId, this.devInfo, this.history);

  static MessageData fromJson(Map<String, dynamic> map) {
    String userId = map["userId"];
    DevInfo devInfo = DevInfo.fromJson(map["devInfo"]);
    History history = History.fromJson(map["history"]);
    return MessageData(userId, devInfo, history);
  }

  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      "devInfo": devInfo.toJson(),
      "history": history.toJson(),
    };
  }
}
