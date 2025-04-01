import 'package:clipshare/app/data/enums/history_content_type.dart';

class SearchFilter {
  String content = "";
  String startDate = "";
  String endDate = "";
  Set<String> tags = {};
  Set<String> devIds = {};
  bool onlyNoSync = false;
  HistoryContentType type = HistoryContentType.all;

  SearchFilter copy() {
    final newFilter = SearchFilter();
    newFilter.content = content;
    newFilter.startDate = startDate;
    newFilter.endDate = endDate;
    newFilter.tags.addAll(tags);
    newFilter.devIds.addAll(devIds);
    newFilter.onlyNoSync = onlyNoSync;
    newFilter.type = type;
    return newFilter;
  }
}
