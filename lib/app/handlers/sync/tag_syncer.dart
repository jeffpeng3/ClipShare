import 'dart:convert';

import 'package:clipshare/app/data/repository/entity/message_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/history_tag.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_sync.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/socket_service.dart';
import 'package:clipshare/app/services/tag_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:get/get.dart';

/// 标签同步处理器
class TagSyncer implements SyncListener {
  final sktService = Get.find<SocketService>();
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final tagService = Get.find<TagService>();

  TagSyncer() {
    sktService.addSyncListener(Module.tag, this);
  }

  void dispose() {
    sktService.removeSyncListener(Module.tag, this);
  }

  @override
  void ackSync(MessageData msg) {
    var send = msg.send;
    var data = msg.data;
    var opSync = OperationSync(
      opId: data["id"],
      devId: send.guid,
      uid: appConfig.userId,
    );
    //记录同步记录
    dbService.opSyncDao.add(opSync);
  }

  @override
  void onSync(MessageData msg) {
    var send = msg.send;
    var opRecord = OperationRecord.fromJson(msg.data);
    Map<String, dynamic> json = jsonDecode(opRecord.data);
    HistoryTag tag = HistoryTag.fromJson(json);
    Future f = Future(() => null);
    switch (opRecord.method) {
      case OpMethod.add:
        f = dbService.historyTagDao.add(tag).then((cnt) {
          tagService.add(tag, false);
          return cnt;
        });
        break;
      case OpMethod.delete:
        f = dbService.historyTagDao.removeById(tag.id).then((cnt) {
          tagService.remove(tag, false);
          return cnt;
        });
        break;
      default:
        return;
    }

    f.then((cnt) {
      if (cnt != null && cnt > 0) {
        dbService.opRecordDao.add(opRecord.copyWith(tag.id.toString()));
      }
      //发送同步确认
      sktService.sendData(
        send,
        MsgType.ackSync,
        {"id": opRecord.id, "module": Module.tag.moduleName},
      );
    });
  }
}
