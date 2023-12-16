import 'package:floor/floor.dart';

@Entity(indices: [
  Index(value: ['tagName', "hisId"], unique: true)
])
class HistoryTag {
  @PrimaryKey(autoGenerate: true)
  ///主键 id
  int? id;

  ///标签名称
  late String tagName;

  /// 历史 id
  late int hisId;

  HistoryTag({
    this.id,
    required this.tagName,
    required this.hisId,
  });
}
