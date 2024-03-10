import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';

extension StringExtension on String {
  bool get hasUrl {
    return matchRegExp(r"[a-zA-z]+://[^\s]*");
  }

  bool get isIPv4 {
    return matchRegExp(
      r"((2(5[0-5]|[0-4]\d))|[0-1]?\d{1,2})(\.((2(5[0-5]|[0-4]\d))|[0-1]?\d{1,2})){3}",
    );
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
      return port >= 0 && port <= 65535;
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
      context: App.context,
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
}
