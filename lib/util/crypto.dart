import 'dart:convert';

import 'package:crypto/crypto.dart';

class CryptoUtil {
  static String toMD5(Object obj) {
    var bytes = utf8.encode(obj.toString());
    var digest = md5.convert(bytes);
    return digest.toString();
  }
}
