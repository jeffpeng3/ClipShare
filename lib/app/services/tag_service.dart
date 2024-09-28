import 'package:clipshare/app/data/repository/entity/tables/history_tag.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:get/get.dart';

class TagService extends GetxService {
  final _dbService = Get.find<DbService>();
  final _tags = <int, Set<String>>{}.obs;

  Future<TagService> init() async {
    final lst = await _dbService.historyTagDao.getAll();
    for (var tag in lst) {
      if (_tags.containsKey(tag.hisId)) {
        _tags[tag.hisId]!.add(tag.tagName);
      } else {
        _tags[tag.hisId] = <String>{}..add(tag.tagName);
      }
    }
    return this;
  }

  Set<String> getTagList(int hisId) {
    if (_tags.containsKey(hisId)) {
      return _tags[hisId]!;
    } else {
      return <String>{};
    }
  }

  Future<void> _remove(HistoryTag tag, [bool notify = true]) async {
    await _dbService.historyTagDao.removeById(tag.id);
    if (_tags.containsKey(tag.hisId)) {
      if (_tags[tag.hisId]!.length == 1) {
        _tags.remove(tag.hisId);
      } else {
        _tags[tag.hisId] = Set.from(_tags[tag.hisId]!..remove(tag.tagName));
      }
    }
    var opRecord = OperationRecord.fromSimple(
      Module.tag,
      OpMethod.delete,
      tag.id.toString(),
    );
    //添加操作记录
    _dbService.opRecordDao.addAndNotify(opRecord);
  }

  Future<bool> _add(HistoryTag tag, [bool notify = true]) async {
    var hasTag = _tags.containsKey(tag.hisId)
        ? _tags[tag.hisId]!.contains(tag.tagName)
        : false;
    var res = false;
    if (hasTag) return false;
    if (notify) {
      res = await _dbService.historyTagDao.add(tag) > 0;
      if (!res) {
        return false;
      }
      var opRecord = OperationRecord.fromSimple(
        Module.tag,
        OpMethod.add,
        tag.id.toString(),
      );
      //添加操作记录
      _dbService.opRecordDao.addAndNotify(opRecord);
    }
    if (!notify || res) {
      if (_tags.containsKey(tag.hisId)) {
        _tags[tag.hisId] = (_tags[tag.hisId]!..add(tag.tagName));
      } else {
        _tags[tag.hisId] = <String>{}..add(tag.tagName);
      }
    }
    return res;
  }

  ///添加
  Future<bool> add(HistoryTag tag, [bool notify = true]) async {
    return await _add(tag, notify);
  }

  ///批量添加
  Future<void> addList(Iterable<HistoryTag> tags, [bool notify = true]) async {
    for (var tag in tags) {
      await _add(tag, notify);
    }
  }

  ///删除 tag
  Future<void> remove(HistoryTag tag, [bool notify = true]) async {
    await _remove(tag, notify);
  }

  ///批量删除
  Future<void> removeList(
    Iterable<HistoryTag> tags, [
    bool notify = true,
  ]) async {
    for (var tag in tags) {
      await _remove(tag, notify);
    }
  }
}
