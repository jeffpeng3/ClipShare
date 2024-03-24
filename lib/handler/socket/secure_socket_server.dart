import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:basic_utils/basic_utils.dart';
import 'package:clipshare/util/crypto.dart';
import 'package:clipshare/util/log.dart';
import 'package:encrypt/encrypt.dart';

class _SocketClientData {
  bool ready;
  String data;
  late final Encrypter _encrypter;
  late final DiffieHellman _dh;
  late final String _aesKey;
  _SocketClientData(this.ready, this.data);
}

class SecureSocketServer {
  final String ip;
  final int port;
  late final ServerSocket _server;
  bool _listening = false;
  late final void Function(String ip, int port) _onConnected;
  late final void Function(String data) _onMessage;
  Function? _onError;
  void Function()? _onDone;
  bool? _cancelOnError;
  late final StreamSubscription _stream;
  final Map<Socket, _SocketClientData> _sktData = {};

  SecureSocketServer._private(this.ip, this.port);

  ///服务端绑定监听端口
  static Future<SecureSocketServer> bind(
    String ip,
    int port,
    void Function(String ip, int port) onConnected,
    void Function(String data) onMessage,
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  ) async {
    var sss = SecureSocketServer._private(ip, port);
    sss._server = await ServerSocket.bind(ip, port);
    sss._onMessage = onMessage;
    sss._onError = onError;
    sss._onConnected = onConnected;
    sss._onDone = onDone;
    sss._listen();
    return sss;
  }

  ///监听新连接
  void _listen() {
    if (_listening) {
      throw Exception("SecureSocketService has started listening");
    }
    _listening = true;
    try {
      _stream = _server.listen(
        (client) {
          _sktData[client] = _SocketClientData(false, "");
          client.listen(
              (e) {
                var rec = utf8.decode(e);
                var lastIdx = rec.length - 1;
                //未接收到结束符，继续等待
                if (rec[lastIdx] != "\n") {
                  _sktData[client]!.data = _sktData[client]!.data + rec;
                  return;
                }
                //去除结束符
                _sktData[client]!.data += rec.substring(0, lastIdx);
                //接收完成，进行解码
                try {
                  if (_sktData[client]!.ready) {
                    //密钥已交换
                    var decrypt = CryptoUtil.decryptAES(
                      key: _sktData[client]!._aesKey,
                      encoded: _sktData[client]!.data,
                      encrypter: _sktData[client]!._encrypter,
                    );
                    _onMessage(decrypt);
                  } else {
                    //密钥未交换
                    var decodeB64 =
                        CryptoUtil.base64Decode(_sktData[client]!.data);
                    _exchange(client, decodeB64);
                  }
                } catch (ex, stack) {
                  print(stack);
                  //解析出错
                  Log.error("SecureSocketServer", "解析出错：$ex");
                } finally {
                  _sktData[client]!.data = "";
                }
              },
              onError: (e) {
                Log.error("SecureSocketClient", "error:$e");
                if (_onError != null) {
                  _onError!(e);
                }
              },
              cancelOnError: _cancelOnError,
              onDone: () {
                if (_sktData.containsKey(client)) {
                  _sktData.remove(client);
                  print("skt len ${_sktData.length}");
                }
              },);
        },
        onError: (e) {
          Log.error("SecureSocketClient", "error:$e");
          if (_onError != null) {
            _onError!(e);
          }
        },
        onDone: _onDone,
        cancelOnError: _cancelOnError,
      );
    } catch (e) {
      _listening = false;
      rethrow;
    }
  }

  ///密钥交换
  void _exchange(Socket client, String msg) {
    var data = jsonDecode(msg);
    //接收公钥，素数和底数g
    var key = data["key"];
    var g = BigInt.parse(data["g"]);
    var prime = BigInt.parse(data["prime"]);
    //生成自己的RSA私钥
    var pairKey = CryptoUtils.generateRSAKeyPair();
    var privateKey = pairKey.privateKey as RSAPrivateKey;
    //使用素数，底数，自己的私钥创建一个DH对象
    _sktData[client]!._dh = DiffieHellman(prime, g, privateKey.n!);
    //根据接收的公钥使用dh算法生成共享秘钥
    var otherPublicKey = BigInt.parse(key);
    //SharedSecretKey
    var ssk = _sktData[client]!._dh.generateSharedSecret(otherPublicKey);
    //计算 aesKey 完成密钥交换
    _sktData[client]!._aesKey = ssk.toString().substring(0, 32);
    _sktData[client]!._encrypter = CryptoUtil.getEncrypter(_sktData[client]!._aesKey);
    //发送自己的publicKey
    Map<String, String> map = {
      "key": _sktData[client]!._dh.publicKey.toString(),
    };
    send(client, jsonEncode(map));
    _setReady(client);
  }

  ///密钥已交换
  void _setReady(Socket socket) {
    if (_sktData[socket]!.ready) {
      throw Exception("already ready");
    }
    _sktData[socket]!.ready = true;
    _onConnected(socket.remoteAddress.address, socket.remotePort);
  }

  ///发送数据
  void send(Socket socket, String data) {
    socket.writeln(CryptoUtil.base64Encode(data));
  }

  ///关闭连接
  Future close() {
    return _server.close();
  }
}
