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
import 'package:get/get.dart';

class MissingDataSyncer {
  static const tag = "SyncDataHandler";

  static void sendMissingData(DevInfo targetDev, List<String> devIds) {
    final sktService = Get.find<SocketService>();
    getData(targetDev.guid, devIds).then((lst) {
      for (var item in lst) {
        sktService.sendData(targetDev, MsgType.missingData, {"data": item});
      }
    });
  }

  static Future<List<OperationRecord>> getData(
      String targetDev, List<String> devIds) {
    final appConfig = Get.find<ConfigService>();
    final dbService = Get.find<DbService>();
    return dbService.opRecordDao
        .getSyncRecord(appConfig.userId, targetDev, devIds)
        .then((lst) {
      var future = Future.value();
      var rmList = <OperationRecord>[];
      for (var item in lst) {
        future = future.then((value) => process(item, rmList));
      }
      return future.then((v) {
        //删除需要移除的item
        lst.removeWhere((element) => rmList.contains(element));
        return lst;
      });
    });
  }

  static Future process(OperationRecord item, List<OperationRecord> rmList) {
    Future f = Future(() => null);
    final appConfig = Get.find<ConfigService>();
    final dbService = Get.find<DbService>();
    var id = item.data;
    switch (item.module) {
      case Module.device:
        f = dbService.deviceDao.getById(id, appConfig.userId).then((v) {
          if (v == null) {
            if (item.method != OpMethod.delete) {
              rmList.add(item);
            } else {
              var empty = Device.empty();
              empty.guid = id;
              empty.uid = appConfig.userId;
              item.data = empty.toString();
            }
          } else {
            item.data = v.toString();
          }
        });
        break;
      case Module.tag:
        f = dbService.historyTagDao.getById(int.parse(id)).then((v) {
          if (v == null) {
            if (item.method != OpMethod.delete) {
              rmList.add(item);
            } else {
              var empty = HistoryTag.empty();
              empty.id = int.parse(id);
              item.data = empty.toString();
            }
          } else {
            item.data = v.toString();
          }
        });
        break;
      case Module.history:
        f = dbService.historyDao.getById(int.parse(id)).then((v) {
          if (v == null) {
            if (item.method != OpMethod.delete) {
              rmList.add(item);
            } else {
              var empty = History.empty();
              empty.id = int.parse(id);
              item.data = empty.toString();
            }
          } else {
            try {
              var clip = ClipData(v);
              if (clip.isImage) {
                var file = File(v.content);
                var fileName = file.fileName;
                var bytes = file.readAsBytesSync();
                v.content = jsonEncode(
                  {"fileName": fileName, "data": bytes},
                );
              }
              item.data = v.toString();
            } catch (e, t) {
              rmList.add(item);
              Log.debug(tag, "$e\n$t");
            }
          }
        });
        break;
      case Module.historyTop:
        f = dbService.historyDao.getById(int.parse(id)).then((v) {
          if (v == null) {
            if (item.method != OpMethod.delete) {
              rmList.add(item);
            }
          } else {
            //更新置顶状态，将内容设为空，提高传输效率
            v.content = "";
            item.data = v.toString();
          }
        });
        break;
      case Module.rules:
        //什么都不做
        break;
      default:
        return Future.value();
    }
    return f;
  }

  static List<List<T>> _partition<T>(List<T> list, int size) {
    List<List<T>> result = [];
    for (var i = 0; i < list.length; i += size) {
      int start = i;
      int end = i + size > list.length ? list.length : i + size;
      var subList = list.sublist(start, end);
      result.add(subList);
    }
    return result;
  }
}
