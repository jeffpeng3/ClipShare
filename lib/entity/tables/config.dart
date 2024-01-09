import 'package:floor/floor.dart';

@entity
class Config {
  ///配置项
  @primaryKey
  late String key;

  ///配置值
  late String value;

  ///用户 id
  late int uid;

  Config({
    required this.key,
    required this.value,
    required this.uid,
  });
}
