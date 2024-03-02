import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../util/crypto.dart';
import '../util/log.dart';

class MySocket {
  late final Socket _socket;
  String recData = "";
  late final String ip;
  late final int port;

  MySocket(Socket socket) {
    _socket = socket;
    ip = socket.remoteAddress.address;
    port = socket.remotePort;
  }

  static Future<MySocket> connect(String ip, int port) async {
    final socket = await Socket.connect(ip, port);
    return MySocket(socket);
  }

  void send(String data) {
    recData = "";
    var b64Data = "${CryptoUtil.base64Encode(data)}\n";
    _socket.write(b64Data);
  }

  StreamSubscription<Uint8List> listen(
    void Function(String data) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _socket.listen(
      (List<int> data) {
        var rec = utf8.decode(data);
        var lastIdx = rec.length - 1;
        //未接收到结束符，继续等待
        if (rec[lastIdx] != "\n") {
          recData += rec;
          return;
        }
        //去除结束符
        recData += rec.substring(0, lastIdx);
        //接收完成，进行解码
        try {
          var decodeB64 = CryptoUtil.base64Decode(recData);
          onData(decodeB64);
        } catch (ex) {
          //解析出错
          Log.error("MySocket", "解析出错：$ex");
        } finally {
          recData = "";
        }
      },
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  Future close() {
    return _socket.close();
  }
  void destroy() async {
    _socket.destroy();
  }
}
