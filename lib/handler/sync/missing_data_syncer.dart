import 'dart:convert';
import 'dart:io';

import 'package:clipshare/db/app_db.dart';
import 'package:clipshare/entity/clip_data.dart';
import 'package:clipshare/entity/dev_info.dart';
import 'package:clipshare/entity/tables/device.dart';
import 'package:clipshare/entity/tables/history.dart';
import 'package:clipshare/entity/tables/history_tag.dart';
import 'package:clipshare/entity/tables/operation_record.dart';
import 'package:clipshare/listeners/socket_listener.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/extension.dart';
import 'package:clipshare/util/log.dart';

class MissingDataSyncer {
  static const tag = "SyncDataHandler";

  static void sendMissingData(DevInfo targetDev,List<String> devIds) {
    getData(targetDev.guid,devIds).then((lst) {
      for (var item in lst) {
        SocketListener.inst.sendData(targetDev, MsgType.missingData, {"data": item});
      }
    });
  }

  static Future<List<OperationRecord>> getData(String targetDev,List<String> devIds) {
    return AppDb.inst.opRecordDao.getSyncRecord(App.userId, targetDev,devIds).then((lst) {
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
    var id = item.data;
    switch (item.module) {
      case Module.device:
        f = AppDb.inst.deviceDao.getById(id, App.userId).then((v) {
          if (v == null) {
            if (item.method != OpMethod.delete) {
              rmList.add(item);
            } else {
              var empty = Device.empty();
              empty.guid = id;
              empty.uid = App.userId;
              item.data = empty.toString();
            }
          } else {
            item.data = v.toString();
          }
        });
        break;
      case Module.tag:
        f = AppDb.inst.historyTagDao.getById(int.parse(id)).then((v) {
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
        f = AppDb.inst.historyDao.getById(int.parse(id)).then((v) {
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
        f = AppDb.inst.historyDao.getById(int.parse(id)).then((v) {
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
