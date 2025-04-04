import 'dart:convert';

import 'package:clipshare/app/data/enums/history_content_type.dart';

class SearchFilter {
  String content = "";
  String startDate = "";
  String endDate = "";
  Set<String> tags = {};
  Set<String> devIds = {};
  bool onlyNoSync = false;
  HistoryContentType type = HistoryContentType.all;

  SearchFilter();

  factory SearchFilter.fromJson(Map<String, dynamic> json) {
    return SearchFilter()
      ..content = json["content"]
      ..startDate = json["startDate"]
      ..endDate = json["endDate"]
      ..tags = (json["tags"] as List<dynamic>? ?? []).map((e) => e.toString()).toSet()
      ..devIds = (json["devIds"] as List<dynamic>? ?? []).map((e) => e.toString()).toSet()
      ..onlyNoSync = json["onlyNoSync"]
      ..type = HistoryContentType.parse(json["type"]);
  }

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

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  Map<String, dynamic> toJson() {
    return {
      "content": content,
      "startDate": startDate,
      "endDate": endDate,
      "tags": tags.toList(),
      "devIds": devIds.toList(),
      "onlyNoSync": onlyNoSync,
      "type": type.value,
    };
  }
}
