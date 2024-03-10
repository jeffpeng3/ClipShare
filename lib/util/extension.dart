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
}
