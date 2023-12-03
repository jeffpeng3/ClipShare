import 'package:floor/floor.dart';

@entity
class Config {
  @PrimaryKey()
  ///配置项
  late String key;

  ///配置值
  late String value;

  ///用户 id（uuid）
  late String uid;

  Config({
    required this.key,
    required this.value,
    required this.uid,
  });
}
