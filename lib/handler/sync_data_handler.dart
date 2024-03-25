import 'package:clipshare/db/db_util.dart';
import 'package:clipshare/entity/dev_info.dart';
import 'package:clipshare/entity/tables/device.dart';
import 'package:clipshare/entity/tables/history.dart';
import 'package:clipshare/entity/tables/history_tag.dart';
import 'package:clipshare/entity/tables/operation_record.dart';
import 'package:clipshare/listeners/socket_listener.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/util/constants.dart';

class SyncDataHandler {
  static void sendMissingData(DevInfo dev) {
    getData(dev.guid).then((lst) {
      for (var item in lst) {
        SocketListener.inst.sendData(dev, MsgType.missingData, {"data": item});
      }
    });
  }

  static Future<List<OperationRecord>> getData(String devId) {
    return DBUtil.inst.opRecordDao.getSyncRecord(App.userId, devId).then((lst) {
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
    Future f;
    var id = item.data;
    switch (item.module) {
      case Module.device:
        f = DBUtil.inst.deviceDao.getById(id, App.userId).then((v) {
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
        f = DBUtil.inst.historyTagDao.getById(int.parse(id)).then((v) {
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
        f = DBUtil.inst.historyDao.getById(int.parse(id)).then((v) {
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
        f = DBUtil.inst.historyDao.getById(int.parse(id)).then((v) {
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
