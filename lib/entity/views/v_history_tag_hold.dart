import 'package:floor/floor.dart';

@DatabaseView("""
SELECT DISTINCT
	ht.hisId,
	ht.tagName,
	(t.hisId is not null) as hasTag 
FROM
	HistoryTag ht
	LEFT JOIN ( SELECT * FROM HistoryTag ) t ON t.hisId = ht.hisId 
""")
class VHistoryTagHold {
  String hisId;
  String tagName;
  bool hasTag;

  VHistoryTagHold(this.hisId, this.tagName, this.hasTag);
}
