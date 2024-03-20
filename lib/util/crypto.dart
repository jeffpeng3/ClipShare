import 'dart:convert';
import 'dart:math';

import 'package:basic_utils/basic_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

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

  /// 返回RSA的pem格式的key
  /// 第一个参数是 privateKey，第二个是 publicKey
  static List<String> genRSAKey() {
    AsymmetricKeyPair pair = CryptoUtils.generateRSAKeyPair();
    var privateKey =
        CryptoUtils.encodeRSAPrivateKeyToPem(pair.privateKey as RSAPrivateKey);
    var publicKey =
        CryptoUtils.encodeRSAPublicKeyToPem(pair.publicKey as RSAPublicKey);
    return [privateKey, publicKey];
  }

  ///加密 RSA 数据
  static String encryptRSA(String publicKey, String data) {
    return CryptoUtils.rsaEncrypt(
      data,
      CryptoUtils.rsaPublicKeyFromPem(publicKey),
    );
  }

  ///解密 RSA 数据
  static String decryptRSA(String privateKey, String data) {
    return CryptoUtils.rsaDecrypt(
      data,
      CryptoUtils.rsaPrivateKeyFromPem(privateKey),
    );
  }

  static Encrypter getEncrypter(String key, [AESMode mode = AESMode.cbc]) {
    final aesKey = Key.fromUtf8(key);
    return Encrypter(AES(aesKey, mode: mode));
  }

  ///加密 AES 数据
  static String encryptAES(String key, String data) {
    final iv = IV.fromUtf8(key);
    return getEncrypter(key).encrypt(data, iv: iv).base64;
  }

  ///解密 AES 数据
  static String decryptAES(String key, String data) {
    final iv = IV.fromUtf8(key);
    return getEncrypter(key).decrypt64(data, iv: iv);
  }

  static String generateRandomKey([
    int len = 16,
    String words = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
  ]) {
    final random = Random.secure();
    // 生成随机密钥
    var lst = List.generate(len, (_) => words[random.nextInt(words.length)]);
    return lst.join('');
  }
}
