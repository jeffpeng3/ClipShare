import 'dart:async';
import 'dart:io';

import 'package:clipshare/entity/message_data.dart';
import 'package:clipshare/handler/socket/secure_socket_client.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/extension.dart';
import 'package:clipshare/util/log.dart';

class FileSyncer {
  static const tag = "FileSyncer";
  static final Map<String, IOSink> _syncingFiles = {};

  static void sendFile({
    required String ip,
    required int port,
    required String path,
    void Function()? onDone,
    void Function(Exception e)? onError,
  }) async {
    try {
      await SecureSocketClient.connect(
        ip: ip,
        port: port,
        prime: App.prime,
        keyPair: App.keyPair,
        tag: "fileSync",
        onError: (e, c) => onError?.call(e),
        onDone: (c) => onDone?.call(),
        onConnected: (client) async {
          final file = File(path);
          const bufferSize = Constants.fileBlock;
          // 使用 transform 设置缓冲区大小
          Stream<List<int>> stream = file.openRead().transform(
            StreamTransformer.fromHandlers(
              handleData: (data, sink) {
                // 将数据分块处理并发送到 sink
                for (int i = 0; i < data.length; i += bufferSize) {
                  int end = (i + bufferSize < data.length)
                      ? i + bufferSize
                      : data.length;
                  sink.add(data.sublist(i, end));
                }
              },
            ),
          );
          if (!file.existsSync()) {
            throw Exception("file not found");
          }
          final fileName = file.fileName;
          var isFirst = true;
          await for (var data in stream) {
            final msg = MessageData(
              userId: App.userId,
              send: App.devInfo,
              key: MsgType.fileBlock,
              data: {
                "fileName": fileName,
                "isFirst": isFirst,
                "block": data,
              },
            );
            isFirst = false;
            client.send(msg.toJson());
          }
          final endMsg = MessageData(
            userId: App.userId,
            send: App.devInfo,
            key: MsgType.transferDone,
            data: {
              "fileName": fileName,
            },
          );
          //此处发送完结束消息后，由接收端断开连接
          client.send(endMsg.toJson());
        },
      );
    } catch (err, stack) {
      Log.error(
        tag,
        "$err: File transfer failed, $ip:$port, path = $path\n $stack",
      );
      onError?.call(err as Exception);
    }
  }

  static void recFile(MessageData msg) {
    if (![MsgType.fileBlock, MsgType.transferDone].contains(msg.key)) {
      return;
    }
    final data = msg.data;
    String fileName = data["fileName"];
    final filePath = "${App.settings.fileStorePath}/$fileName";
    if (msg.key == MsgType.transferDone) {
      //传输完成
      _syncingFiles[filePath]?.close();
      _syncingFiles.remove(filePath);
      return;
    }
    List<int> bytes = (data["block"] as List<dynamic>).cast<int>();
    bool isFirst = data["isFirst"];
    final file = File(filePath);
    if (isFirst) {
      if (_syncingFiles.containsKey(filePath)) {
        throw Exception("File are being synchronized: $filePath");
      }
      var sink = file.openWrite();
      _syncingFiles[filePath] = sink;
    }
    try {
      _syncingFiles[filePath]!.add(bytes);
    } catch (e) {
      //出错，中断传输
      _syncingFiles[filePath]?.close();
      _syncingFiles.remove(filePath);
      rethrow;
    }
  }

  static void clear(MessageData msg) {
    if (![MsgType.fileBlock, MsgType.transferDone].contains(msg.key)) {
      return;
    }
    final data = msg.data;
    String fileName = data["fileName"];
    final filePath = "${App.settings.fileStorePath}/$fileName";
    var sink = _syncingFiles[filePath];
    _syncingFiles.remove(filePath);
    sink?.close();
  }
}
