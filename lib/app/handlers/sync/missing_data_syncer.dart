import 'dart:convert';
import 'dart:io';

import 'package:clipshare/app/data/repository/entity/clip_data.dart';
import 'package:clipshare/app/data/repository/entity/dev_info.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/data/repository/entity/tables/history_tag.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/socket_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class MissingDataSyncer {
  static const tag = "SyncDataHandler";

  static void sendMissingData(DevInfo targetDev, List<String> devIds) async {
    final appConfig = Get.find<ConfigService>();
    final dbService = Get.find<DbService>();
    final lst = await dbService.opRecordDao
        .getSyncRecord(appConfig.userId, targetDev.guid, devIds);
    var i = 1;
    final sktService = Get.find<SocketService>();
    for (var item in lst) {
      await process(item).then((shouldRemove) {
        print("process ${i++}/${lst.length}");
        if (shouldRemove) {
          return dbService.opRecordDao.deleteByIds([item.id]);
        } else {
          return sktService.sendData(
            targetDev,
            MsgType.missingData,
            {"data": item},
          );
        }
      });
    }
  }

  static Future<bool> process(OperationRecord opRecord) async {
    final appConfig = Get.find<ConfigService>();
    final dbService = Get.find<DbService>();
    var shouldRemove = false;
    var id = opRecord.data;
    switch (opRecord.module) {
      case Module.device:
        await dbService.deviceDao.getById(id, appConfig.userId).then((v) {
          //数据库不存在该数据
          if (v == null) {
            //如果不是delete方法就移除
            if (opRecord.method != OpMethod.delete) {
              shouldRemove = true;
            } else {
              var empty = Device.empty();
              empty.guid = id;
              empty.uid = appConfig.userId;
              opRecord.data = empty.toString();
            }
          } else {
            opRecord.data = v.toString();
          }
        });
        break;
      case Module.tag:
        await dbService.historyTagDao.getById(int.parse(id)).then((v) {
          if (v == null) {
            if (opRecord.method != OpMethod.delete) {
              shouldRemove = true;
            } else {
              var empty = HistoryTag.empty();
              empty.id = int.parse(id);
              opRecord.data = empty.toString();
            }
          } else {
            opRecord.data = v.toString();
          }
        });
        break;
      case Module.history:
        await dbService.historyDao.getById(int.parse(id)).then((v) async {
          if (v == null) {
            if (opRecord.method != OpMethod.delete) {
              shouldRemove = true;
            } else {
              var empty = History.empty();
              empty.id = int.parse(id);
              opRecord.data = empty.toString();
            }
          } else {
            try {
              if (ClipData(v).isImage) {
                var content = await compute(
                  (History v) {
                    var file = File(v.content);
                    var fileName = file.fileName;
                    var bytes = file.readAsBytesSync();
                    v.content = jsonEncode(
                      {"fileName": fileName, "data": bytes},
                    );
                    return v.toString();
                  },
                  v,
                );
                opRecord.data = content;
              } else {
                opRecord.data = v.toString();
              }
            } catch (e, t) {
              shouldRemove = true;
              Log.debug(tag, "$e\n$t");
            }
          }
        });
        break;
      case Module.historyTop:
        await dbService.historyDao.getById(int.parse(id)).then((v) {
          if (v == null) {
            if (opRecord.method != OpMethod.delete) {
              shouldRemove = true;
            }
          } else {
            //更新置顶状态，将内容设为空，提高传输效率
            v.content = "";
            opRecord.data = v.toString();
          }
        });
        break;
      case Module.rules:
        //什么都不做
        break;
      default:
    }
    return shouldRemove;
  }
}
