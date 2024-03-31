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
  void Function(Exception e, String ip, int port)? _onClientError;
  void Function(String ip, int port)? _onClientDone;
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
    void Function(Exception e, String ip, int port)? onClientError,
    void Function(String ip, int port)? onClientDone,
  }) async {
    var sss = SecureSocketServer._private(ip, port);
    sss._server = await ServerSocket.bind(ip, port);
    sss._onMessage = onMessage;
    sss._onError = onError;
    sss._onConnected = onConnected;
    sss._onDone = onDone;
    sss._onClientDone = onClientDone;
    sss._onClientError = onClientError;
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
          String ip = client.remoteAddress.address;
          int port = client.remotePort;
          var ssc = SecureSocketClient.fromSocket(
            socket: client,
            prime: App.prime,
            keyPair: App.keyPair,
            onConnected: (SecureSocketClient ssc) {
              _onConnected(ip, port);
            },
            onMessage: _onMessage,
            onDone: () {
              if (_onClientDone != null) {
                _onClientDone!.call(ip, port);
              }
              if (_sktList.contains(client)) {
                _sktList.remove(client);
              }
            },
            onError: (e) {
              Log.error("SecureSocketClient", "error:$e");
              if (_onClientError != null) {
                _onClientError!(e, ip, port);
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
