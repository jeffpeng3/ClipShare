import 'dart:async';
import 'dart:io';

import 'package:clipshare/handler/socket/secure_socket_client.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/util/log.dart';

class SecureSocketServer {
  final String ip;
  final int port;
  late final ServerSocket _server;
  bool _listening = false;
  late final void Function(String ip, int port) _onConnected;
  late final void Function(SecureSocketClient client, String data) _onMessage;
  Function? _onError;
  void Function()? _onDone;
  bool? _cancelOnError;
  late final StreamSubscription _stream;
  final Set<SecureSocketClient> _sktList = {};

  SecureSocketServer._private(this.ip, this.port);

  ///服务端绑定监听端口
  static Future<SecureSocketServer> bind({
    required String ip,
    required int port,
    required void Function(String ip, int port) onConnected,
    required void Function(SecureSocketClient client, String data) onMessage,
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) async {
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
          var ssc = SecureSocketClient.fromSocket(
            socket: client,
            prime: App.prime,
            keyPair: App.keyPair,
            onConnected: (SecureSocketClient ssc) {
              _onConnected(client.remoteAddress.address, client.remotePort);
            },
            onMessage: _onMessage,
            onDone: () {
              if (_sktList.contains(client)) {
                _sktList.remove(client);
              }
            },
            cancelOnError: _cancelOnError,
          );
          _sktList.add(ssc);
        },
        onError: (e, stack) {
          Log.error("SecureSocketServer", "error:$e");
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

  ///发送数据
  void send(SecureSocketClient client, Map map) {
    client.send(map);
  }

  ///关闭连接
  Future close() {
    return _server.close();
  }
}
