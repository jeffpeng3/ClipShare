import 'package:clipshare/entity/tables/history.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/extension.dart';

class ClipData {
  ClipData(this._data);

  final History _data;

  History get data => _data;

  bool get isImage => _data.type == ContentType.image.value;

  bool get isText => _data.type == ContentType.text.value;

  bool get isFile => _data.type == ContentType.file.value;

  String get timeStr => getTimeStr();

  bool get isRichText => _data.type == ContentType.richText.value;

  String get sizeText {
    int size = data.size;
    if (isText || isRichText) return "$size 字";
    return size.sizeStr;
  }

  String getTimeStr() {
    String time = "";
    DateTime now = DateTime.now();
    Duration difference = now.difference(DateTime.parse(data.time));

    if (difference.inMinutes < 1) {
      time = "刚刚";
    } else if (difference.inHours < 1) {
      int minutes = difference.inMinutes;
      time = "$minutes分钟前";
    } else if (difference.inHours < 24) {
      int hours = difference.inHours;
      time = "$hours小时前";
    } else {
      time = data.time.substring(0, 19); // 使用默认的日期时间格式
    }

    return time;
  }

  static List<ClipData> fromList(List<History> list) {
    List<ClipData> res = List.empty(growable: true);
    for (int i = 0; i < list.length; i++) {
      res.add(ClipData(list[i]));
    }
    return res;
  }
}
