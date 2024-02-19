import 'dart:convert';

import 'package:clipshare/entity/message_data.dart';
import 'package:clipshare/entity/tables/history_tag.dart';
import 'package:clipshare/listeners/socket_listener.dart';
import 'package:clipshare/util/constants.dart';

import '../db/db_util.dart';
import '../entity/tables/operation_record.dart';
import '../entity/tables/operation_sync.dart';
import '../main.dart';

/// 标签同步处理器
class TagSyncer implements SyncObserver {
  TagSyncer() {
    SocketListener.inst.addSyncListener(Module.tag, this);
  }

  void destroy() {
    SocketListener.inst.removeSyncListener(Module.tag, this);
  }

  @override
  void ackSync(MessageData msg) {
    var send = msg.send;
    var data = msg.data;
    var opSync =
        OperationSync(opId: data["id"], devId: send.guid, uid: App.userId);
    //记录同步记录
    DBUtil.inst.opSyncDao.add(opSync);
  }

  @override
  void onSync(MessageData msg) {
    var send = msg.send;
    var opRecord = OperationRecord.fromJson(msg.data);
    Map<String, dynamic> json = jsonDecode(opRecord.data);
    HistoryTag tag = HistoryTag.fromJson(json);
    Future? f;
    switch (opRecord.method) {
      case OpMethod.add:
        f = DBUtil.inst.historyTagDao.add(tag);
        break;
      case OpMethod.delete:
        DBUtil.inst.historyTagDao.removeById(tag.id);
        break;
      case OpMethod.update:
        f = DBUtil.inst.historyTagDao.updateTag(tag);
        break;
      default:
        return;
    }

    if (f == null) {
      //发送同步确认
      SocketListener.inst.sendData(
        send,
        MsgType.ackSync,
        {"id": opRecord.id, "module": Module.tag.moduleName},
      );
    } else {
      f.then((cnt) {
        if (cnt <= 0) return;
        //发送同步确认
        SocketListener.inst.sendData(
          send,
          MsgType.ackSync,
          {"id": opRecord.id, "module": Module.tag.moduleName},
        );
      });
    }
  }
}
