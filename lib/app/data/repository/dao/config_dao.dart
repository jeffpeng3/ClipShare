import 'package:clipshare/app/data/repository/entity/tables/config.dart';
import 'package:floor/floor.dart';

@dao
abstract class ConfigDao {
  ///获取所有配置项
  @Query("select * from config where uid = :uid")
  Future<List<Config>> getAllConfigs(int uid);

  ///获取某个配置项
  @Query("select `value` from config where `key` = :key and uid = :uid")
  Future<String?> getConfig(String key, int uid);

  ///添加一个配置
  @insert
  Future<int> add(Config config);

  ///更新配置
  @update
  Future<int> updateConfig(Config config);

  ///删除配置
  @delete
  Future<int> remove(Config config);

  ///根据 key 删除配置
  @Query("delete from config where key = :key and uid = :uid")
  Future<void> removeByKey(String key, int uid);
}
