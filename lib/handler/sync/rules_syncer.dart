import 'dart:convert';

import 'package:clipshare/db/app_db.dart';
import 'package:clipshare/entity/message_data.dart';
import 'package:clipshare/entity/tables/operation_record.dart';
import 'package:clipshare/entity/tables/operation_sync.dart';
import 'package:clipshare/listeners/socket_listener.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/provider/setting_provider.dart';
import 'package:clipshare/util/constants.dart';
import 'package:refena_flutter/refena_flutter.dart';

///规则同步器
class RulesSyncer implements SyncListener {
  final Ref ref;

  RulesSyncer(this.ref) {
    SocketListener.inst.addSyncListener(Module.rules, this);
  }

  void dispose() {
    SocketListener.inst.removeSyncListener(Module.rules, this);
  }

  @override
  void ackSync(MessageData msg) {
    var send = msg.send;
    var data = msg.data;
    var opSync = OperationSync(
      opId: data["id"],
      devId: send.guid,
      uid: App.userId,
    );
    //记录同步记录
    AppDb.inst.opSyncDao.add(opSync);
  }

  @override
  void onSync(MessageData msg) {
    var send = msg.send;
    var opRecord = OperationRecord.fromJson(msg.data);
    Map<String, dynamic> json = jsonDecode(opRecord.data);
    Future f = Future(() => null);
    Rule rule = Rule.getValue(json["rule"]);
    Map<String, dynamic> data = json["data"];
    int newVersion = data["version"];

    switch (rule) {
      case Rule.tag:
        var localTagRules = jsonDecode(App.settings.tagRegulars);
        var localVersion = localTagRules["version"];
        if (localVersion <= newVersion) {
          //小于发送过来的版本，更新本地
          f.then((v) {
            ref.notifier(settingProvider).setTagRegulars(jsonEncode(data));
          });
        }
        break;
      default:
        return;
    }

    f.then((cnt) {
      //发送同步确认
      SocketListener.inst.sendData(
        send,
        MsgType.ackSync,
        {"id": opRecord.id, "module": Module.rules.moduleName},
      );
    });
  }
}
