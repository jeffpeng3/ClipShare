import 'package:clipshare/dao/history_tag_dao.dart';
import 'package:clipshare/db/db_util.dart';
import 'package:clipshare/entity/tables/history_tag.dart';
import 'package:clipshare/entity/tables/operation_record.dart';
import 'package:clipshare/util/constants.dart';
import 'package:refena_flutter/refena_flutter.dart';

class HistoryTagMap {
  late final Map<int, Set<String>> _map;

  HistoryTagMap(this._map);

  Set<String> getTagList(int hisId) {
    if (_map.containsKey(hisId)) {
      return _map[hisId]!;
    }
    return {};
  }

  HistoryTagMap copy() {
    return HistoryTagMap(Map.from(_map));
  }
}

class HistoryTagProvider extends Notifier<HistoryTagMap> {
  final HistoryTagDao _historyTagDao = DBUtil.inst.historyTagDao;
  static HistoryTagMap? _tagsMap;
  static NotifierProvider<HistoryTagProvider, HistoryTagMap> inst =
      NotifierProvider<HistoryTagProvider, HistoryTagMap>((ref) {
    return HistoryTagProvider();
  });

  @override
  HistoryTagMap init() {
    if (_tagsMap == null) {
      //初始化标签列表
      DBUtil.inst.historyTagDao.getAll().then((lst) {
        _initState(lst);
      });
    }
    return _tagsMap ?? HistoryTagMap({});
  }

  Future<bool> _remove(HistoryTag tag, [bool notify = true]) async {
    var cnt = await _historyTagDao.removeById(tag.id);
    var res = cnt != null && cnt > 0;
    if (!res) return false;
    if (state._map.containsKey(tag.hisId)) {
      if (state._map[tag.hisId]!.length == 1) {
        state._map.remove(tag.hisId);
      } else {
        state._map[tag.hisId]!.remove(tag.tagName);
      }
    }
    if (!notify) {
      return res;
    }
    var opRecord = OperationRecord.fromSimple(
      Module.tag,
      OpMethod.delete,
      tag.id.toString(),
    );
    //添加操作记录
    DBUtil.inst.opRecordDao.addAndNotify(opRecord);
    return true;
  }

  Future<bool> _add(HistoryTag tag, [bool notify = true]) async {
    var hasTag = state._map.containsKey(tag.hisId)
        ? state._map[tag.hisId]!.contains(tag.tagName)
        : false;
    var res = false;
    if (hasTag) return false;
    if (notify) {
      res = await _historyTagDao.add(tag) > 0;
      if (!res) {
        return false;
      }
      var opRecord = OperationRecord.fromSimple(
        Module.tag,
        OpMethod.add,
        tag.id.toString(),
      );
      //添加操作记录
      DBUtil.inst.opRecordDao.addAndNotify(opRecord);
    }
    if (!notify || res) {
      if (state._map.containsKey(tag.hisId)) {
        state._map[tag.hisId]!.add(tag.tagName);
      } else {
        state._map[tag.hisId] = <String>{}..add(tag.tagName);
      }
    }
    return res;
  }

  ///添加
  Future<bool> add(HistoryTag tag, [bool notify = true]) async {
    var res = await _add(tag, notify);
    if (!res) {
      return false;
    }
    _tagsMap = state = state.copy();
    return true;
  }

  ///批量添加
  Future<void> addList(Iterable<HistoryTag> tags, [bool notify = true]) async {
    for (var tag in tags) {
      var res = await _add(tag, notify);
      if (!res) {
        continue;
      }
    }
    _tagsMap = state = state.copy();
  }

  ///删除 tag
  Future<bool> remove(HistoryTag tag, [bool notify = true]) async {
    var res = await _remove(tag, notify);
    if (!res) {
      return false;
    }
    _tagsMap = state = state.copy();
    return true;
  }

  ///批量删除
  Future<void> removeList(Iterable<HistoryTag> tags,
      [bool notify = true]) async {
    for (var tag in tags) {
      var res = await _remove(tag, notify);
      if (!res) {
        continue;
      }
    }
    _tagsMap = state = state.copy();
  }

  ///初始化标签 map
  void _initState(Iterable<HistoryTag> tags) {
    Map<int, Set<String>> map = {};
    for (var tag in tags) {
      if (map.containsKey(tag.hisId)) {
        map[tag.hisId]!.add(tag.tagName);
      } else {
        map[tag.hisId] = <String>{}..add(tag.tagName);
      }
    }
    _tagsMap = state = HistoryTagMap(map);
  }
}
