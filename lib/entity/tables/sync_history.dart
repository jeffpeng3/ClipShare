import 'package:floor/floor.dart';

@Entity(indices: [Index(value: ['devId',"hisId"])])
class SyncHistory {
  @PrimaryKey(autoGenerate: true)
  ///主键 id
  int? id;

  ///设备 id
  late String devId;

  /// 历史 id
  late int hisId;

  SyncHistory({
    this.id,
    required this.devId,
    required this.hisId,
  });
}
