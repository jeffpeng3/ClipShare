import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

extension StringExt on String {
  bool get hasUrl {
    return matchRegExp(r"[a-zA-z]+://[^\s]*");
  }

  String substringMinLen(int start, int end) {
    return substring(start, min(end, length));
  }

  bool matchRegExp(String regExp, [bool caseSensitive = false]) {
    var reg = RegExp(
      regExp,
      caseSensitive: caseSensitive,
    );
    return reg.hasMatch(this);
  }

  bool get isPort {
    try {
      var port = int.parse(this);
      return port > 0 && port <= 65535;
    } catch (e) {
      return false;
    }
  }

  int toInt() {
    return int.parse(this);
  }

  bool toBool() {
    return bool.parse(this);
  }

  double toDouble() {
    return double.parse(this);
  }

  void askOpenUrl() {
    if (!hasUrl) return;
    showModalBottomSheet(
      context: Get.context!,
      clipBehavior: Clip.antiAlias,
      elevation: 100,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: IntrinsicHeight(
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "打开链接",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        openUrl();
                        Navigator.pop(context);
                      },
                      child: const Text("打开"),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Linkify(
                  text: this,
                  options: const LinkifyOptions(humanize: false),
                  linkStyle: const TextStyle(
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 5),
              ],
            ),
          ),
        );
      },
    );
  }

  void openUrl() async {
    var uri = Uri.parse(this);
    await launchUrl(uri);
  }

  String replaceLast(String target, String replacement) {
    int lastIndex = lastIndexOf(target);
    if (lastIndex == -1) return this; // 如果找不到目标字符串，直接返回原字符串
    return replaceRange(
      lastIndex,
      lastIndex + target.length,
      replacement,
    );
  }
}

extension StringNilExt on String? {
  bool get isNotNullAndEmpty => this != null && this!.isNotEmpty;

  bool get isNullOrEmpty => this == null || this!.isEmpty;
}
