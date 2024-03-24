import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:basic_utils/basic_utils.dart';
import 'package:clipshare/util/crypto.dart';
import 'package:clipshare/util/log.dart';
import 'package:encrypt/encrypt.dart';

class SecureSocketClient {
  final String ip;
  final int port;
  late final Socket _socket;
  bool _listening = false;
  String _data = "";
  bool _ready = false;
  late final void Function() _onConnected;
  late final void Function(String data) _onMessage;
  Function? _onError;
  void Function()? _onDone;
  bool? _cancelOnError;
  late final StreamSubscription _stream;
  late final Encrypter _encrypter;
  late final DiffieHellman _dh;
  late final String _aesKey;

  SecureSocketClient._private(this.ip, this.port);

  ///连接 socket
  static Future<SecureSocketClient> connect(
    String ip,
    int port,
    void Function() onConnected,
    void Function(String data) onMessage,
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  ) async {
    var ssc = SecureSocketClient._private(ip, port);
    ssc._socket = await Socket.connect(ip, port);
    ssc._onMessage = onMessage;
    ssc._onConnected = onConnected;
    ssc._onError = onError;
    ssc._onDone = onDone;
    ssc._sendKey();
    ssc._listen();
    return ssc;
  }

  ///监听消息
  void _listen() {
    if (_listening) {
      throw Exception("SecureSocketService has started listening");
    }
    _listening = true;
    try {
      _stream = _socket.listen(
        (e) {
          var rec = utf8.decode(e);
          var lastIdx = rec.length - 1;
          //未接收到结束符，继续等待
          if (rec[lastIdx] != "\n") {
            _data += rec;
            return;
          }
          //去除结束符
          _data += rec.substring(0, lastIdx);
          //接收完成，进行解码
          if (_ready) {
            //密钥已交换
            try {
              //此处需要解密
              var decrypt = CryptoUtil.decryptAES(
                key: _aesKey,
                encoded: _data,
                encrypter: _encrypter,
              );
              _onMessage(decrypt);
            } catch (ex) {
              //解析出错
              Log.error("SecureSocketClient", "解析出错：$ex");
            } finally {
              _data = "";
            }
          } else {
            //密钥未交换
            var decodeB64 = CryptoUtil.base64Decode(_data);
            _exchange(decodeB64);
          }
        },
        onError: (e) {
          _data = "";
          Log.error("SecureSocketClient", "error:$e");
          if (_onError != null) {
            _onError!(e);
          }
        },
        onDone: () {
          _socket.close();
          if (_ready) {
            _onDone?.call();
          }
        },
        cancelOnError: _cancelOnError,
      );
    } catch (e) {
      _listening = false;
      rethrow;
    }
  }

  ///密钥交换
  void _exchange(String msg) {
    var data = jsonDecode(msg);
    //接收公钥
    var key = data["key"];
    var otherPublicKey = BigInt.parse(key);
    //SharedSecretKey
    var ssk = _dh.generateSharedSecret(otherPublicKey);
    //计算 aesKey 完成密钥交换
    _aesKey = ssk.toString().substring(0, 32);
    _encrypter = CryptoUtil.getEncrypter(_aesKey);
    _setReady();
  }

  ///密钥已交换
  void _setReady() {
    if (_ready) {
      throw Exception("already ready");
    }
    _ready = true;
    _onConnected();
  }

  ///发送数据
  void send(String data) {
    if(_ready) {
      data = CryptoUtil.encryptAES(key: _aesKey, input: data,encrypter: _encrypter);
    }else{
      data = CryptoUtil.base64Encode(data);
    }
    _socket.writeln(data);
  }

  ///DH 算法发送 key 和 素数、底数
  void _sendKey() {
    if (_ready) {
      throw Exception("already ready");
    }
    //创建自己的RSA秘钥
    var pair = CryptoUtils.generateRSAKeyPair();
    var privateKey = pair.privateKey as RSAPrivateKey;
    //生成素数
    var prim = CryptoUtil.getPrim();
    //底数g
    var g = BigInt.from(65537);
    //创建DH对象
    _dh = DiffieHellman(prim, g, privateKey.n!);
    //发送素数，底数，公钥
    Map<String, String> map = {
      "prime": prim.toString(),
      "g": g.toString(),
      "key": _dh.publicKey.toString(),
    };
    send(jsonEncode(map));
  }

  ///关闭连接
  Future close() {
    return _socket.close();
  }

  ///强制关闭
  void destroy() {
    return _socket.destroy();
  }
}
