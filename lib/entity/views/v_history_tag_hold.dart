import 'package:clipshare/entity/tables/history_tag.dart';
import 'package:floor/floor.dart';

@DatabaseView("""
select t1.* ,(t2.hisId is not null) as hasTag 
from (
  SELECT distinct h.id as hisId,tag.tagName
  FROM
    history as h,historyTag as tag
) t1
LEFT JOIN ( SELECT * FROM HistoryTag ) t2
ON t2.hisId = t1.hisId and t2.tagName = t1.tagName
""")
class VHistoryTagHold {
  int hisId;
  String tagName;
  bool hasTag;

  VHistoryTagHold(this.hisId, this.tagName, this.hasTag);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VHistoryTagHold &&
          runtimeType == other.runtimeType &&
          hisId == other.hisId &&
          tagName == other.tagName;

  @override
  int get hashCode => hisId.hashCode ^ tagName.hashCode;

  Map<String, dynamic> toJson() {
    return {"hisId": hisId, "tagName": tagName, "hasTag": hasTag};
  }

  @override
  String toString() {
    return toJson().toString();
  }
}
