import 'dart:convert';

import 'package:crypto/crypto.dart';

class CryptoUtil {
  static String toMD5(Object obj) {
    var bytes = utf8.encode(obj.toString());
    var digest = md5.convert(bytes);
    return digest.toString();
  }

  static String base64Encode(String input) {
    // Encode the input string to Base64
    List<int> bytes = utf8.encode(input);
    String encodedString = base64.encode(bytes);
    return encodedString;
  }

  static String base64Decode(String input) {
    // Decode the Base64 string to the original string
    List<int> bytes = base64.decode(input);
    String decodedString = utf8.decode(bytes);
    return decodedString;
  }
}
