import 'package:clipshare/entity/tables/history_tag.dart';
import 'package:floor/floor.dart';

import '../entity/views/v_history_tag_hold.dart';

@dao
abstract class HistoryTagDao {
  ///查询某个记录的标签列表
  @Query("select * from HistoryTag where hisId = :hId")
  Future<List<HistoryTag>> list(String hId);

  ///查询所有标签，返回值含有一个该历史 id 是否持有该标签的标记
  @Query("SELECT * from VHistoryTagHold where hisId = :hId")
  Future<List<VHistoryTagHold>> listWithHold(String hId);

  ///插入一条标签
  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<int> add(HistoryTag tag);

  ///删除标签
  @Query("delete from HistoryTag where hisId = :hId and tagName = :tagName ")
  Future<int?> remove(String hId, String tagName);
}
