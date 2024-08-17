import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clipshare/util/log.dart';

class TransferSocketClient {
  final String ip;
  late final int _port;

  int get port => _port;
  late final Socket _socket;
  bool _listening = false;
  String _data = "";
  static const endChar = "\n";
  late final void Function(TransferSocketClient client, String data)?
      _onMessage;
  void Function(Exception e, TransferSocketClient client)? _onError;
  void Function(TransferSocketClient client)? _onDone;
  bool? _cancelOnError;
  late final StreamSubscription _stream;
  static const String tag = "TransferSocketClient";

  final StreamController<String> _msgStreamController = StreamController();

  TransferSocketClient._private(this.ip) {
    _msgStreamController.stream.listen((data) {
      try {
        _socket.writeln(data);
      } catch (e, stack) {
        _msgStreamController.close();
        Log.debug(tag, "发送失败：$e");
        Log.debug(tag, "$stack");
        _onDone?.call(this);
      }
    });
  }

  static TransferSocketClient empty =
      TransferSocketClient._private("127.0.0.1");

  ///连接 socket
  static Future<TransferSocketClient> connect({
    required String ip,
    required int port,
    void Function(TransferSocketClient)? onConnected,
    void Function(TransferSocketClient client, String data)? onMessage,
    void Function(Exception e, TransferSocketClient client)? onError,
    void Function(TransferSocketClient client)? onDone,
    bool? cancelOnError,
  }) async {
    var socket = await Socket.connect(
      ip,
      port,
      timeout: const Duration(seconds: 2),
    );
    var ssc = TransferSocketClient.fromSocket(
      socket: socket,
      onMessage: onMessage,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
    onConnected?.call(ssc);
    return ssc;
  }

  factory TransferSocketClient.fromSocket({
    required Socket socket,
    int? serverPort,
    required void Function(TransferSocketClient self, String data)? onMessage,
    void Function(Exception e, TransferSocketClient self)? onError,
    void Function(TransferSocketClient self)? onDone,
    bool? cancelOnError,
  }) {
    var ssc = TransferSocketClient._private(socket.remoteAddress.address);
    if (serverPort != null) {
      ssc._port = serverPort;
    }
    ssc._socket = socket;
    ssc._onMessage = onMessage;
    ssc._onError = onError;
    ssc._onDone = onDone;
    ssc._cancelOnError = cancelOnError;
    ssc._listen();
    return ssc;
  }

  ///监听消息
  void _listen() {
    if (_listening) {
      throw Exception("TransferSocketClient has started listening");
    }
    _listening = true;
    try {
      _stream = _socket.listen(
        (e) {
          var rec = utf8.decode(e);
          _data += rec;
          while (_data.contains(endChar)) {
            // 以结束符分割数据包，找到第一个完整的数据包
            var index = _data.indexOf(endChar);
            var pkg = _data.substring(0, index + 1);
            Log.debug(tag, pkg);
            _data = _data.substring(index + 1);
            try {
              _onMessage?.call(this, pkg);
            } catch (ex, stack) {
              //解析出错
              Log.error(tag, "解析出错：$ex\n$stack");
            }
          }
        },
        onError: (e) {
          _data = "";
          Log.error(tag, "error:$e");
          if (_onError != null) {
            _onError!(e, this);
          }
        },
        onDone: () {
          _onDone?.call(this);
          Log.debug(tag, "_onDone");
          _socket.close();
        },
        cancelOnError: _cancelOnError,
      );
    } catch (e) {
      _listening = false;
      rethrow;
    }
  }

  ///发送数据
  void send(Map map) {
    var data = jsonEncode(map);
    try {
      _msgStreamController.add(data);
    } catch (e, stack) {
      Log.debug(tag, "发送失败：$e");
      Log.debug(tag, "_onDone ${_onDone == null}");
      Log.debug(tag, "$stack");
      if (_onDone != null) {
        _onDone!.call(this);
      }
    }
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
