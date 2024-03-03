extension StringExtension on String {
  bool get hasUrl {
    var reg = RegExp(
      r"[a-zA-z]+://[^\s]*",
      caseSensitive: false,
    );
    return reg.hasMatch(this);
  }

  bool get isIPv4 {
    var reg = RegExp(
      r"((2(5[0-5]|[0-4]\d))|[0-1]?\d{1,2})(\.((2(5[0-5]|[0-4]\d))|[0-1]?\d{1,2})){3}",
      caseSensitive: false,
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
}
