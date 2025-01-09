import 'package:clipshare/app/data/enums/module.dart';
import 'package:clipshare/app/data/enums/msg_type.dart';
import 'package:clipshare/app/data/enums/op_method.dart';
import 'package:clipshare/app/data/models/message_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/history_tag.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_sync.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/socket_service.dart';
import 'package:clipshare/app/services/tag_service.dart';
import 'package:get/get.dart';

/// 标签同步处理器
class TagSyncHandler implements SyncListener {
  final sktService = Get.find<SocketService>();
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final tagService = Get.find<TagService>();

  TagSyncHandler() {
    sktService.addSyncListener(Module.tag, this);
  }

  void dispose() {
    sktService.removeSyncListener(Module.tag, this);
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
  Future onSync(MessageData msg) async {
    var send = msg.send;
    final map = msg.data;
    final tagMap = map["data"] as Map<dynamic, dynamic>;
    map["data"] = "";
    var opRecord = OperationRecord.fromJson(map);
    HistoryTag tag = HistoryTag.fromJson(tagMap.cast());
    bool success = false;
    switch (opRecord.method) {
      case OpMethod.add:
        success = await dbService.historyTagDao.add(tag) > 0;
        tagService.add(tag, false);
        break;
      case OpMethod.delete:
        //delete后仅有id，无hisId，需要本地查一次
        final dbTag = await dbService.historyTagDao.getById(tag.id);
        success = await dbService.historyTagDao
                .removeById(tag.id)
                .then((cnt) => cnt ?? 0) >
            0;
        if (dbTag != null) {
          tagService.remove(dbTag, false);
        }
        break;
      default:
    }
    if (success) {
      await dbService.opRecordDao.add(opRecord.copyWith(tag.id.toString()));
    }
    //发送同步确认
    sktService.sendData(
      send,
      MsgType.ackSync,
      {"id": opRecord.id, "module": Module.tag.moduleName},
    );
  }
}
