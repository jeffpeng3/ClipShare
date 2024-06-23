import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clipshare/enum/connection_mode.dart';
import 'package:clipshare/enum/forward_msg_type.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/util/crypto.dart';
import 'package:clipshare/util/extension.dart';
import 'package:clipshare/util/log.dart';
import 'package:encrypt/encrypt.dart';

class SecureSocketClient {
  final String ip;
  late final int _port;

  int get port => _port;
  late final Socket _socket;
  bool _listening = false;
  String _data = "";
  bool _keyIsExchanged = false;
  late final void Function(SecureSocketClient)? _onConnected;
  late final void Function(SecureSocketClient client, String data)? _onMessage;
  void Function(Exception e, SecureSocketClient client)? _onError;
  void Function(SecureSocketClient client)? _onDone;
  bool? _cancelOnError;
  late final StreamSubscription _stream;
  late final Encrypter _encrypter;
  late final DiffieHellman _dh;
  late final String _aesKey;
  late final BigInt _prime1;
  late final BigInt _prime2;
  static const tag = "SecureSocketClient";
  late final String _targetDevId;
  late final String _selfDevId;
  late final ConnectionMode _connectionMode;
  bool _forwardReady = false;

  bool get isReady => _keyIsExchanged;

  bool get isForwardMode => _connectionMode == ConnectionMode.forward;

  String get _endChar => isForwardMode && !_forwardReady ? '\n' : ',';
  final StreamController<String> _msgStreamController = StreamController();

  SecureSocketClient._private(this.ip) {
    _msgStreamController.stream.listen((data) {
      try {
        _socket.write(data);
      } catch (e, stack) {
        _msgStreamController.close();
        Log.debug("SecureSocketClient", "发送失败：$e");
        Log.debug("SecureSocketClient", "$stack");
        _onDone?.call(this);
      }
    });
  }

  static SecureSocketClient empty = SecureSocketClient._private("127.0.0.1");

  ///连接 socket
  static Future<SecureSocketClient> connect({
    required String ip,
    required int port,
    required BigInt prime1,
    required BigInt prime2,
    ConnectionMode connectionMode = ConnectionMode.direct,
    String? targetDevId,
    String? selfDevId,
    void Function(SecureSocketClient)? onConnected,
    void Function(SecureSocketClient client, String data)? onMessage,
    void Function(Exception e, SecureSocketClient client)? onError,
    void Function(SecureSocketClient client)? onDone,
    bool? cancelOnError,
  }) async {
    var socket = await Socket.connect(
      ip,
      port,
      timeout: const Duration(seconds: 2),
    );
    var ssc = SecureSocketClient.fromSocket(
      socket: socket,
      prime1: prime1,
      prime2: prime2,
      connectionMode: connectionMode,
      targetDevId: targetDevId,
      selfDevId: selfDevId,
      onConnected: onConnected,
      onMessage: onMessage,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
    if (ssc._connectionMode == ConnectionMode.direct) {
      //直连模式主动连接，发送素数，底数，公钥
      ssc.sendKey();
    } else {
      //中转模式发送初始信息
      ssc.send({
        "self": selfDevId,
        "target": targetDevId,
      });
    }
    return ssc;
  }

  factory SecureSocketClient.fromSocket({
    required Socket socket,
    required BigInt prime1,
    required BigInt prime2,
    ConnectionMode connectionMode = ConnectionMode.direct,
    String? targetDevId,
    String? selfDevId,
    int? serverPort,
    void Function(SecureSocketClient)? onConnected,
    required void Function(SecureSocketClient client, String data)? onMessage,
    void Function(Exception e, SecureSocketClient client)? onError,
    void Function(SecureSocketClient client)? onDone,
    bool? cancelOnError,
  }) {
    final isForward = connectionMode == ConnectionMode.forward;
    if (isForward) {
      assert(targetDevId.isNotNullAndEmpty);
      assert(selfDevId.isNotNullAndEmpty);
    }
    var ssc = SecureSocketClient._private(socket.remoteAddress.address);
    if (serverPort != null) {
      ssc._port = serverPort;
    }
    ssc._connectionMode = connectionMode;
    ssc._targetDevId = targetDevId!;
    ssc._selfDevId = selfDevId!;
    ssc._prime1 = prime1;
    ssc._prime2 = prime2;
    ssc._socket = socket;
    ssc._onMessage = onMessage;
    ssc._onConnected = onConnected;
    ssc._onError = onError;
    ssc._onDone = onDone;
    ssc._cancelOnError = cancelOnError;
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
          _data += rec;
          while (_data.contains(_endChar)) {
            // 以结束符分割数据包，找到第一个完整的数据包
            var index = _data.indexOf(_endChar);
            var pkg = _data.substring(0, index);
            _data = _data.substring(index + 1);
            //接收完成，进行解码
            try {
              if (isForwardMode && !_forwardReady) {
                //中转未准备好
                var json = jsonDecode(pkg);
                var type = ForwardMsgType.getValue(json["type"]);
                Log.debug(tag, "forward ${type.name}");
                switch (type) {
                  case ForwardMsgType.bothConnected:
                    send({"type": ForwardMsgType.bothConnected.name});
                    String sender = json["sender"];
                    if (sender != _selfDevId) {
                      _forwardReady = true;
                    }
                    break;
                  case ForwardMsgType.forwardReady:
                    _forwardReady = true;
                    sendKey();
                    break;
                  case ForwardMsgType.alreadyConnected:
                    close();
                    break;
                  default:
                }
              } else {
                //region 数据处理
                if (_keyIsExchanged) {
                  //密钥已交换，此处需要解密
                  var decrypt = CryptoUtil.decryptAES(
                    key: _aesKey,
                    encoded: pkg,
                    encrypter: _encrypter,
                  );
                  if (_onMessage != null) {
                    _onMessage(this, decrypt);
                  }
                } else {
                  //密钥未交换
                  var decodeB64 = CryptoUtil.base64DecodeStr(pkg);
                  _exchange(decodeB64);
                }
                //endregion
              }
            } catch (ex, stack) {
              //解析出错
              Log.error("SecureSocketClient", "解析出错：$ex\n$stack");
            }
          }
        },
        onError: (e) {
          _data = "";
          Log.error("SecureSocketClient", "error:$e");
          if (_onError != null) {
            _onError!(e, this);
          }
        },
        onDone: () {
          if (_keyIsExchanged) {
            _onDone?.call(this);
          }
          Log.debug("SecureSocketClient", "_onDone");
          _socket.close();
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
    //A(client) -------> B(server)
    if (data["seq"] == 1) {
      //接收公钥，素数和底数g
      var key = data["key"];
      var g = BigInt.parse(data["g"]);
      var prime = BigInt.parse(data["prime"]);
      //使用素数，底数，自己的私钥创
      //建一个DH对象
      _dh = DiffieHellman(prime, g, _prime2);
      //根据接收的公钥使用dh算法生成共享秘钥
      var otherPublicKey = BigInt.parse(key);
      //SharedSecretKey
      var ssk = _dh.generateSharedSecret(otherPublicKey);
      //计算 aesKey 完成密钥交换
      _aesKey = ssk.toString().substring(0, 32);
      _encrypter = CryptoUtil.getEncrypter(_aesKey);
      _port = data["port"];
      //发送自己的publicKey
      Map<String, dynamic> map = {
        "seq": 2,
        "key": _dh.publicKey.toString(),
        "port": App.settings.port,
      };
      //发送
      send(map);
    }
    //A(client) <------- B(server)
    if (data["seq"] == 2) {
      //接收公钥
      var key = data["key"];
      _port = data["port"];
      var otherPublicKey = BigInt.parse(key);
      //SharedSecretKey
      var ssk = _dh.generateSharedSecret(otherPublicKey);
      //计算 aesKey 完成密钥交换
      _aesKey = ssk.toString().substring(0, 32);
      _encrypter = CryptoUtil.getEncrypter(_aesKey);
    }
    _setKeyIsExchanged();
  }

  ///密钥已交换
  void _setKeyIsExchanged() {
    if (_keyIsExchanged) {
      throw Exception("already ready");
    }
    _keyIsExchanged = true;
    if (_onConnected != null) {
      _onConnected(this);
    }
  }

  ///发送数据
  void send(Map map) {
    String data = jsonEncode(map);
    if (!isForwardMode || _forwardReady) {
      //region 直连模式
      if (_keyIsExchanged) {
        data = CryptoUtil.encryptAES(
          key: _aesKey,
          input: data,
          encrypter: _encrypter,
        );
      } else {
        data = CryptoUtil.base64EncodeStr(data);
      }
      //endregion
    }
    try {
      _msgStreamController.add("$data$_endChar");
    } catch (e, stack) {
      Log.debug(tag, "发送失败：$e");
      Log.debug(tag, "_onDone ${_onDone == null}");
      Log.debug(tag, "$stack");
      if (_onDone != null) {
        _onDone!.call(this);
      }
    }
  }

  ///DH 算法发送 key 和 素数、底数
  void sendKey() {
    if (_keyIsExchanged) {
      throw Exception("already ready");
    }
    //底数g
    var g = BigInt.from(65537);
    //创建DH对象
    _dh = DiffieHellman(_prime1, g, _prime2);
    //发送素数，底数，公钥
    Map<String, dynamic> map = {
      "seq": 1,
      "prime": _prime1.toString(),
      "g": g.toString(),
      "key": _dh.publicKey.toString(),
      "port": App.settings.port,
    };
    send(map);
  }

  ///关闭连接
  Future close() {
    _msgStreamController.close();
    return _socket.close();
  }

  ///强制关闭
  void destroy() {
    _msgStreamController.close();
    return _socket.destroy();
  }
}
