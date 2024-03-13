import 'dart:convert';

import 'package:clipshare/entity/message_data.dart';
import 'package:clipshare/entity/tables/history.dart';
import 'package:clipshare/listeners/socket_listener.dart';
import 'package:clipshare/pages/nav/history_page.dart';
import 'package:clipshare/util/constants.dart';
import 'package:flutter/cupertino.dart';

import '../db/db_util.dart';
import '../entity/tables/operation_record.dart';
import '../entity/tables/operation_sync.dart';
import '../main.dart';

/// 记录置顶操作同步处理器
class HistoryTopSyncer implements SyncListener {

  HistoryTopSyncer() {
    SocketListener.inst.addSyncListener(Module.historyTop, this);
  }

  void destroy() {
    SocketListener.inst.removeSyncListener(Module.historyTop, this);
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
    DBUtil.inst.opSyncDao.add(opSync);
  }

  @override
  void onSync(MessageData msg) {
    var send = msg.send;
    var opRecord = OperationRecord.fromJson(msg.data);
    Map<String, dynamic> json = jsonDecode(opRecord.data);
    History history = History.fromJson(json);
    Future? f;
    switch (opRecord.method) {
      case OpMethod.update:
        f = DBUtil.inst.historyDao.setTop(history.id, history.top);
        break;
      default:
        return;
    }

    f.then((cnt) {
      HistoryPage.pageKey.currentState?.updatePage(
        (his) => his.id == history.id,
        (his) => his.top = history.top,
      );
      //发送同步确认
      SocketListener.inst.sendData(
        send,
        MsgType.ackSync,
        {"id": opRecord.id, "module": Module.historyTop.moduleName},
      );
    });
  }
}
