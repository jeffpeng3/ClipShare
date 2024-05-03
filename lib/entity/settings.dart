import 'dart:io';

import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/extension.dart';

class Settings {
  //端口
  int port;

  //本地名称（设备名称）
  String localName;

  //开机启动
  bool launchAtStartup;

  //启动最小化
  bool startMini;

  //允许自动发现
  bool allowDiscover;

  //显示历史悬浮窗
  bool showHistoryFloat;

  //锁定悬浮窗位置
  bool lockHistoryFloatLoc;

  //是否第一次打开软件
  bool firstStartup;

  //记录的上次窗口大小，格式为：widthxheight。默认值为：1000x650
  final String windowSize;
  final bool rememberWindowSize;

  //标签规则
  final String tagRegulars;
  //启用日志记录
  final bool enableLogsRecord;
  //历史记录弹窗快捷键
  final String historyWindowHotKeys;
  //心跳间隔时长
  final int heartbeatInterval;
  //文件存储路径
  final String fileStorePath;

  Settings({
    required this.port,
    required this.localName,
    required this.launchAtStartup,
    required this.startMini,
    required this.allowDiscover,
    required this.showHistoryFloat,
    required this.firstStartup,
    required this.windowSize,
    required this.rememberWindowSize,
    required this.lockHistoryFloatLoc,
    required this.enableLogsRecord,
    required this.tagRegulars,
    required this.historyWindowHotKeys,
    required this.heartbeatInterval,
    required this.fileStorePath,
  });

  Settings copyWith({
    int? port,
    String? localName,
    bool? launchAtStartup,
    bool? startMini,
    bool? allowDiscover,
    bool? showHistoryFloat,
    bool? firstStartup,
    String? windowSize,
    bool? rememberWindowSize,
    bool? lockHistoryFloatLoc,
    bool? enableLogsRecord,
    String? tagRegulars,
    String? historyWindowHotKeys,
    int? heartbeatInterval,
    String? fileStorePath,
  }) {
    return Settings(
      port: port ?? this.port,
      localName: localName ?? this.localName,
      launchAtStartup: launchAtStartup ?? this.launchAtStartup,
      startMini: startMini ?? this.startMini,
      allowDiscover: allowDiscover ?? this.allowDiscover,
      showHistoryFloat: showHistoryFloat ?? this.showHistoryFloat,
      firstStartup: firstStartup ?? this.firstStartup,
      windowSize:
          windowSize.isNullOrEmpty ? Constants.defaultWindowSize : windowSize!,
      rememberWindowSize: rememberWindowSize ?? this.rememberWindowSize,
      lockHistoryFloatLoc: lockHistoryFloatLoc ?? this.lockHistoryFloatLoc,
      enableLogsRecord: enableLogsRecord ?? this.enableLogsRecord,
      tagRegulars: tagRegulars ?? this.tagRegulars,
      historyWindowHotKeys: historyWindowHotKeys ?? this.historyWindowHotKeys,
      heartbeatInterval: heartbeatInterval ?? this.heartbeatInterval,
      fileStorePath: Directory(fileStorePath ?? this.fileStorePath).absolute.normalizePath,
    );
  }
}
