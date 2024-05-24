import 'dart:io';

import 'package:clipshare/listeners/socket_listener.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/extension.dart';
import 'package:clipshare/util/log.dart';

class _SyncingFile {
  final int totalSize;
  int _lastFlushBytes = 0;
  int _savedBytes = 0;

  void addSavedBytes(int savedSize) {
    assert(savedSize >= 0);
    _savedBytes += savedSize;
    if (_savedBytes - _lastFlushBytes > 1024 * 1024) {
      _lastFlushBytes = _savedBytes;
    }
  }

  int get getSavedBytes => _savedBytes;

  _SyncingFile(this.totalSize) : assert(totalSize >= 0);
}

class FileSyncer {
  static const tag = "FileSyncer";
  late ServerSocket _server;
  Set<int> clients = {};

  FileSyncer._private(
    String path,
    void Function(FileSyncer) onReady,
    void Function() onDone,
  ) {
    final file = File(path);
    if (!file.existsSync()) {
      throw Exception("file not found");
    }
    ServerSocket.bind(InternetAddress.anyIPv4, 0).then((server) {
      _server = server;
      onReady(this);
      _server.listen((client) async {
        int hash = client.hashCode;
        clients.add(hash);
        client.addStream(file.openRead()).catchError((err, stack) {
          Log.error(tag, "send file failed: $path. $err $stack");
        }).whenComplete(() {
          clients.remove(hash);
          checkClientsIsEmpty(onDone);
          client.close();
        });
      });
      checkClientsIsEmpty(onDone);
    });
  }

  ///在一定时间后检查是否有客户端连接，若无客户端则关闭服务
  void checkClientsIsEmpty(void Function() onDone) {
    Future.delayed(const Duration(seconds: 5), () {
      if (clients.isNotEmpty) return;
      Log.info(tag, "No client connection for more than 5 seconds");
      _server.close();
      onDone();
    });
  }

  ///发送文件
  static void sendFile(String path, void Function() onDone) async {
    FileSyncer._private(
      path,
      (syncer) async {
        final file = File(path);
        int totalSize = await file.length();
        SocketListener.inst.sendData(null, MsgType.file, {
          "fileName": file.fileName,
          "size": totalSize,
          "port": syncer._server.port,
        });
      },
      onDone,
    );
  }

  ///发送多个文件
  static sendFiles(List<String> paths, [int i = 0]) {
    if (i >= paths.length) {
      return;
    }
    sendFile(paths[i], () => sendFiles(paths, i + 1));
  }

  static Future<void> recFile(
    String ip,
    int port,
    int size,
    String fileName,
  ) async {
    var socket = await Socket.connect(ip, port);
    String filePath = "${App.settings.fileStorePath}/$fileName";
    File file = File(filePath);
    IOSink sink = file.openWrite();
    _SyncingFile fileProgress = _SyncingFile(size);
    var start = DateTime.now();

    ///文件存在处理策略（待定）
    // int i = 1;
    // while (file.existsSync()) {
    //   //如果文件存在，给文件加后缀
    //   file = File("$filePath($i)");
    //   i++;
    // }
    socket.listen(
      (bytes) {
        sink.add(bytes);
        fileProgress.addSavedBytes(bytes.length);
      },
      onDone: () {
        var end = DateTime.now();
        int offset = end.difference(start).inSeconds;
        int speed = size ~/ offset;
        Log.info(
          tag,
          "onDone $offset seconds, size: ${size.sizeStr}, speed: ${speed.sizeStr}/s",
        );
      },
    );
  }
}
