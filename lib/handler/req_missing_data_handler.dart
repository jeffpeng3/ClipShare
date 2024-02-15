import 'package:clipshare/db/db_util.dart';
import 'package:clipshare/entity/dev_info.dart';
import 'package:clipshare/entity/tables/device.dart';
import 'package:clipshare/entity/tables/history.dart';
import 'package:clipshare/entity/tables/history_tag.dart';
import 'package:clipshare/entity/tables/operation_record.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/util/constants.dart';

class ReqMissingDataHandler {
  static Future<List<OperationRecord>> getData(DevInfo reqDev) {
    return DBUtil.inst.opRecordDao
        .getSyncRecord(App.userId, reqDev.guid)
        .then((lst) {
      var future = Future.value();
      var rmList = <OperationRecord>[];
      for (var item in lst) {
        Future t;
        var id = item.data;
        switch (item.module) {
          case Module.device:
            t = DBUtil.inst.deviceDao.getById(id, App.userId).then((v) {
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
            t = DBUtil.inst.historyTagDao.getById(int.parse(id)).then((v) {
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
            t = DBUtil.inst.historyDao.getById(int.parse(id)).then((v) {
              if (v == null) {
                if (item.method != OpMethod.delete) {
                  rmList.add(item);
                } else {
                  var empty = History.empty();
                  empty.id = int.parse(id);
                  item.data = empty.toString();
                }
              } else {
                item.data = v.toString();
              }
            });
            break;
          case Module.historyTop:
            t = DBUtil.inst.historyDao.getById(int.parse(id)).then((v) {
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
          default:
            t = Future.value();
            break;
        }
        future = future.then((value) => t);
      }
      return future.then((v) {
        //删除需要移除的item
        lst.removeWhere((element) => rmList.contains(element));
        return lst;
      });
    });
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
