import 'package:floor/floor.dart';

import '../entity/tables/history.dart';

@dao
abstract class HistoryDao {
  ///获取最新记录
  @Query("select * from history where uid = :uid order by id desc limit 1")
  Future<History?> getLatestLocalClip(int uid);

  /// 【废弃】获取某设备未同步的记录
  @Query(
    "SELECT * FROM history h WHERE NOT EXISTS (SELECT 1 FROM SyncHistory sh WHERE sh.hisId = h.id AND sh.devId = :devId) and h.devId != :devId",
  )
  Future<List<History>> getMissingHistory(String devId);

  ///获取前20条历史记录
  @Query("select * from history where uid = :uid order by top,id desc limit 20")
  Future<List<History>> getHistoriesTop20(int uid);

  ///获取前20条历史记录
  @Query(
    "select * from history where uid = :uid and id < :fromId order by top,id desc limit 20",
  )
  Future<List<History>> getHistoriesPage(int uid, int fromId);

  ///置顶/取消置顶某记录
  @Query("update history set top = :top where id = :id ")
  Future<int?> setTop(int id, bool top);

  ///更新记录同步状态
  @Query("update history set sync = :sync where id = :id ")
  Future<int?> setSync(int id, bool sync);

  ///添加一条历史记录
  @insert
  Future<int> add(History history);

  ///删除某条记录
  @Query("delete from history where id = :id")
  Future<int?> delete(int id);

  ///将本地记录转换到某个用户
  @Query("update history set uid = :uid where uid = 0")
  Future<int?> transformLocalToUser(int uid);

  ///删除本地记录用户记录
  @Query("delete from history where uid = 0")
  Future<int?> removeAllLocalHistories();

  ///根据id获取记录
  @Query("select * from history where id = :id")
  Future<History?> getById(int id);

  @update
  Future<int> updateHistory(History history);
}
