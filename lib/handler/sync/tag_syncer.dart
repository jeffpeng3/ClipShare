import 'dart:convert';

import 'package:clipshare/db/app_db.dart';
import 'package:clipshare/entity/message_data.dart';
import 'package:clipshare/entity/tables/history_tag.dart';
import 'package:clipshare/entity/tables/operation_record.dart';
import 'package:clipshare/entity/tables/operation_sync.dart';
import 'package:clipshare/listeners/socket_listener.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/provider/history_tag_provider.dart';
import 'package:clipshare/util/constants.dart';
import 'package:refena_flutter/refena_flutter.dart';

/// 标签同步处理器
class TagSyncer implements SyncListener {
  TagSyncer() {
    SocketListener.inst.addSyncListener(Module.tag, this);
  }

  void dispose() {
    SocketListener.inst.removeSyncListener(Module.tag, this);
  }

  @override
  void ackSync(MessageData msg) {
    var send = msg.send;
    var data = msg.data;
    var opSync =
        OperationSync(opId: data["id"], devId: send.guid, uid: App.userId);
    //记录同步记录
    AppDb.inst.opSyncDao.add(opSync);
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
        f = AppDb.inst.historyTagDao.add(tag).then((cnt) {
          App.context.notifier(HistoryTagProvider.inst).add(tag, false);
        });
        break;
      case OpMethod.delete:
        AppDb.inst.historyTagDao.removeById(tag.id).then((cnt) {
          App.context.notifier(HistoryTagProvider.inst).remove(tag, false);
        });
        break;
      case OpMethod.update:
        //todo 应该没有更新操作
        f = AppDb.inst.historyTagDao.updateTag(tag);
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
