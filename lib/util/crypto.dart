import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt_io.dart';
import 'package:pointycastle/asn1/primitives/asn1_sequence.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/api.dart' as api;
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

  /// 利用公钥进行加密
  static String encryptString(
      {required String publicKeyString, required String plainText}) {
    final publicKey = _parsePublicKeyFromPem(publicKeyString);

    final encrypter = Encrypter(RSA(publicKey: publicKey));

    final encryptedText = encrypter.encrypt(plainText);

    return encryptedText.base64;
  }

  /// 生成公钥和私钥
  static generateKeys() {
    final keyPair = _generateRSAKeyPair();
    final publicKeyString = keyPair.publicKey.toString();
    final privateKeyString = keyPair.privateKey.toString();
    // 将DER格式编码的公钥转换为PEM格式
    String pemPublicKey = ;
    print('公钥:\n$publicKeyString');
    print('私钥:\n$privateKeyString');
  }
  String publicKey2Pem(RSAPublicKey publicKey){
    ASN1Sequence sequence = ASN1Sequence();
    sequence.add(RSAPublicKeyASN1.encodePublicKey(publicKey));
    Uint8List derEncodedPublicKey = sequence.encodedBytes;
    return '''-----BEGIN PUBLIC KEY-----
${_formatPEM(derEncodedPublicKey)}
-----END PUBLIC KEY-----''';
  }
  /// 将字节数据格式化为每行64个字符的PEM格式
  String _formatPEM(Uint8List bytes) {
    String base64String = base64.encode(bytes);
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < base64String.length; i += 64) {
      buffer.write(base64String.substring(i, i + 64));
      buffer.write('\n');
    }
    return buffer.toString();
  }
  static AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> _generateRSAKeyPair() {
    final secureRandom = api.SecureRandom('Fortuna')
      ..seed(KeyParameter(Uint8List(32)));
    final rsaParams = RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 64);

    final keyGenerator = RSAKeyGenerator()
      ..init(ParametersWithRandom(rsaParams, secureRandom));

    final keyPair = keyGenerator.generateKeyPair();

    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
      keyPair.publicKey as RSAPublicKey,
      keyPair.privateKey as RSAPrivateKey,
    );
  }

  /// 通过PEM字符串解析公钥字符串
  static RSAPublicKey _parsePublicKeyFromPem(String pemString) {
    final key = RSAKeyParser().parse(pemString);
    return key as RSAPublicKey;
  }
}
