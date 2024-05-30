import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:clipshare/db/app_db.dart';
import 'package:clipshare/entity/dev_info.dart';
import 'package:clipshare/entity/syncing_file.dart';
import 'package:clipshare/entity/tables/device.dart';
import 'package:clipshare/entity/tables/history.dart';
import 'package:clipshare/listeners/socket_listener.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/pages/nav/history_page.dart';
import 'package:clipshare/provider/syncing_file_progress_providr.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/extension.dart';
import 'package:clipshare/util/log.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:refena_flutter/refena_flutter.dart';

class FileSyncer {
  static const tag = "FileSyncer";
  late ServerSocket _server;
  final int _fileId = App.snowflake.nextId();
  bool hasClient = false;

  FileSyncer._private({
    required String path,
    required void Function(FileSyncer) onReady,
    required void Function() onDone,
    required BuildContext context,
  }) {
    final file = File(path);
    if (!file.existsSync()) {
      throw Exception("file not found");
    }
    ServerSocket.bind(InternetAddress.anyIPv4, 0).then((server) {
      _server = server;
      onReady(this);
      _server.listen((client) async {
        hasClient = true;
        DateTime start = DateTime.now();
        SyncingFile syncingFile = SyncingFile(
          totalSize: file.lengthSync(),
          context: context,
          filePath: file.normalizePath,
          fromDev: App.device,
          isSender: true,
          startTime: DateTime.now().format("yyyy-MM-dd HH:mm:ss"),
          onClose: (done) {
            if (done) {
              return;
            }
            client.destroy();
            context.ref
                .notifier(syncingFileProgressProvider)
                .removeSyncingFile(path);
          },
        );
        //添加到provider
        context.ref
            .read(syncingFileProgressProvider)
            .updateSyncingFile(syncingFile);
        var stream = file.openRead().transform(
          StreamTransformer<List<int>, List<int>>.fromHandlers(
            handleData: (data, sink) {
              syncingFile.addBytes(data);
              sink.add(data);
            },
          ),
        );
        syncingFile.setState(SyncingFileState.syncing);
        client.addStream(stream).then((value) {
          var history = History(
            id: _fileId,
            uid: App.userId,
            devId: App.devInfo.guid,
            time: start.toString(),
            content: path,
            type: ContentType.file.value,
            size: file.lengthSync(),
            sync: true,
          );
          var historyPageState = HistoryPage.pageKey.currentState;
          if (historyPageState == null) {
            AppDb.inst.historyDao.add(history);
          } else {
            historyPageState.addData(history, false);
          }
          syncingFile.setState(SyncingFileState.done);
        }).catchError((err, stack) {
          syncingFile.setState(SyncingFileState.error);
          Log.error(tag, "send file failed: $path. $err $stack");
        }).whenComplete(() {
          client.close();
          _server.close();
          onDone();
        });
      });
      checkHasClient(onDone);
    });
  }

  ///在一定时间后检查是否有客户端连接，若无客户端则关闭服务
  void checkHasClient(void Function() onDone) {
    Future.delayed(const Duration(seconds: 5), () {
      if (hasClient) return;
      Log.info(tag, "No client connection for more than 5 seconds");
      _server.close();
      onDone();
    });
  }

  ///发送文件
  ///[device] 发送的设备
  ///[path] 发送的文件地址
  static void sendFile({
    required Device device,
    required String path,
    required void Function() onDone,
    required BuildContext context,
  }) async {
    FileSyncer._private(
      path: path,
      context: context,
      onReady: (syncer) async {
        final file = File(path);
        int totalSize = await file.length();
        SocketListener.inst.sendData(DevInfo.fromDevice(device), MsgType.file, {
          "fileName": file.fileName,
          "size": totalSize,
          "port": syncer._server.port,
          "fileId": syncer._fileId,
        });
      },
      onDone: onDone,
    );
  }

  ///给多个设备发送多个文件
  ///[devices] 发送的设备列表
  ///[paths] 发送的文件列表
  ///[i] 发送第几个文件
  static sendFiles({
    required List<Device> devices,
    required List<String> paths,
    required BuildContext context,
    int i = 0,
  }) {
    if (i >= devices.length) {
      return;
    }
    //给每个设备发送文件
    sendDevFiles(
      device: devices[i],
      paths: paths,
      context: context,
      onDone: () => sendFiles(
        devices: devices,
        paths: paths,
        i: i + 1,
        context: context,
      ),
    );
  }

  ///给设备发送多个文件
  ///[device] 发送的设备
  ///[paths] 发送的文件列表
  ///[onDone] 发送完成事件
  ///[i] 发送第几个文件
  static sendDevFiles({
    required Device device,
    required List<String> paths,
    required void Function() onDone,
    required BuildContext context,
    int i = 0,
  }) {
    if (i >= paths.length) {
      onDone();
      return;
    }
    sendFile(
      device: device,
      path: paths[i],
      context: context,
      onDone: () => sendDevFiles(
        device: device,
        paths: paths,
        onDone: onDone,
        i: i + 1,
        context: context,
      ),
    );
  }

  static Future<void> recFile({
    required String ip,
    required int port,
    required int size,
    required String fileName,
    required String devId,
    required int userId,
    required int fileId,
    required BuildContext context,
  }) async {
    Device? dev = await AppDb.inst.deviceDao.getById(devId, App.userId);
    if (dev == null) {
      Log.error(tag, "dev:$devId not found");
      return;
    }
    var socket = await Socket.connect(ip, port);
    String filePath = "${App.settings.fileStorePath}/$fileName";
    File file = File(filePath);
    SyncingFile syncingFile = SyncingFile(
      totalSize: size,
      context: context,
      filePath: filePath,
      fromDev: dev,
      sink: file.openWrite(),
      isSender: false,
      startTime: DateTime.now().format("yyyy-MM-dd HH:mm:ss"),
      onClose: (done) {
        if (done) {
          return;
        }
        socket.destroy();
        context.ref
            .notifier(syncingFileProgressProvider)
            .removeSyncingFile(filePath);
      },
    );
    context.ref
        .read(syncingFileProgressProvider)
        .updateSyncingFile(syncingFile);
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
        syncingFile.addBytes(bytes);
      },
      onError: (err, stack) {
        Log.error(tag, "receive file failed. $err $stack");
        file.delete();
        syncingFile.close(false);
      },
      cancelOnError: true,
      onDone: () {
        var end = DateTime.now();
        int offset = max(end.difference(start).inSeconds, 1);
        int speed = size ~/ offset;
        Log.info(
          tag,
          "onDone $offset seconds, size: ${size.sizeStr}, speed: ${speed.sizeStr}/s",
        );
        syncingFile.close(true);
        var history = History(
          id: fileId,
          uid: userId,
          devId: devId,
          time: start.toString(),
          content: filePath,
          type: ContentType.file.value,
          size: size,
          sync: true,
        );
        var historyPageState = HistoryPage.pageKey.currentState;
        if (historyPageState == null) {
          AppDb.inst.historyDao.add(history);
        } else {
          historyPageState.addData(history, false);
        }
      },
    );
  }
}
