import 'dart:convert';

import 'package:clipshare/app/data/repository/entity/message_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_sync.dart';
import 'package:clipshare/app/modules/history_module/history_controller.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/socket_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:get/get.dart';

/// 记录置顶操作同步处理器
class HistoryTopSyncer implements SyncListener {
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final sktService = Get.find<SocketService>();
  final historyController = Get.find<HistoryController>();

  HistoryTopSyncer() {
    sktService.addSyncListener(Module.historyTop, this);
  }

  void dispose() {
    sktService.removeSyncListener(Module.historyTop, this);
  }

  @override
  Future ackSync(MessageData msg) {
    var send = msg.send;
    var data = msg.data;
    var opSync = OperationSync(
      opId: data["id"],
      devId: send.guid,
      uid: appConfig.userId,
    );
    //记录同步记录
    return dbService.opSyncDao.add(opSync);
  }

  @override
  Future onSync(MessageData msg) {
    var send = msg.send;
    var opRecord = OperationRecord.fromJson(msg.data);
    Map<String, dynamic> json = jsonDecode(opRecord.data);
    History history = History.fromJson(json);
    Future? f;
    switch (opRecord.method) {
      case OpMethod.update:
        f = dbService.historyDao.setTop(history.id, history.top);
        break;
      default:
        return Future.value();
    }

    return f.then((cnt) {
      Future f = Future.value();
      if (cnt != null && cnt > 0) {
        //同步成功后在本地也记录一次
        var originOpRecord = opRecord.copyWith(history.id.toString());
        f = dbService.opRecordDao.add(originOpRecord);
      }
      historyController.updateData(
        (his) => his.id == history.id,
        (his) => his.top = history.top,
      );
      //发送同步确认
      sktService.sendData(
        send,
        MsgType.ackSync,
        {"id": opRecord.id, "module": Module.historyTop.moduleName},
      );
      return f;
    });
  }
}
