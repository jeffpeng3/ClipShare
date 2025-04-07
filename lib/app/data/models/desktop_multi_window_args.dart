import 'dart:convert';

import 'package:clipshare/app/data/enums/multi_window_tag.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DesktopMultiWindowArgs {
  final MultiWindowTag tag;
  final String title;
  final String languageCode;
  String? countryCode;
  final ThemeMode themeMode;
  final Map<String, dynamic> otherArgs;

  DesktopMultiWindowArgs._private({
    required this.tag,
    required this.title,
    required this.languageCode,
    this.countryCode,
    required this.themeMode,
    this.otherArgs = const {},
  });

  factory DesktopMultiWindowArgs.init({
    required String title,
    required MultiWindowTag tag,
    required ThemeMode? themeMode,
    Map<String, dynamic> otherArgs = const {},
  }) {
    final locale = Get.locale!;
    themeMode = themeMode == ThemeMode.system || themeMode == null
        ? Get.isPlatformDarkMode
            ? ThemeMode.dark
            : ThemeMode.light
        : themeMode;
    return DesktopMultiWindowArgs._private(
      tag: tag,
      title: title,
      languageCode: locale.languageCode,
      countryCode: locale.countryCode,
      themeMode: themeMode,
      otherArgs: otherArgs,
    );
  }

  @override
  String toString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() {
    var map = {
      "tag": tag.name,
      "title": title,
      "languageCode": languageCode,
      "themeMode": themeMode.name,
      "otherArgs": otherArgs,
    };
    if (countryCode != null) {
      map["countryCode"] = countryCode!;
    }
    return map;
  }

  factory DesktopMultiWindowArgs.fromJson(Map<String, dynamic> json) {
    ThemeMode themeMode = !json.containsKey('themeMode') || json['themeMode'] == "system"
        ? Get.isPlatformDarkMode
            ? ThemeMode.dark
            : ThemeMode.light
        : json['themeMode'] == "light"
            ? ThemeMode.light
            : ThemeMode.dark;
    return DesktopMultiWindowArgs._private(
      tag: MultiWindowTag.getValue(json['tag']!),
      title: json['title']!,
      languageCode: json['languageCode']!,
      countryCode: json['countryCode'],
      themeMode: themeMode,
      otherArgs: json["otherArgs"] ?? {},
    );
  }
}
