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
  final String tagRules;

  //短信规则
  final String smsRules;

  //启用日志记录
  final bool enableLogsRecord;

  //历史记录弹窗快捷键
  final String historyWindowHotKeys;

  //文件同步快捷键
  final String syncFileHotKeys;

  //心跳间隔时长
  final int heartbeatInterval;

  //文件存储路径
  final String fileStorePath;

  //保存至相册
  final bool saveToPictures;

  //忽略Shizuku权限
  final bool ignoreShizuku;

  //使用安全认证
  final bool useAuthentication;

  //app密码重新验证时长
  final int appRevalidateDuration;

  //app密码
  final String? appPassword;

  //是否启用短信同步
  final bool enableSmsSync;

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
    required this.tagRules,
    required this.smsRules,
    required this.historyWindowHotKeys,
    required this.heartbeatInterval,
    required this.fileStorePath,
    required this.saveToPictures,
    required this.ignoreShizuku,
    required this.useAuthentication,
    required this.appRevalidateDuration,
    required this.syncFileHotKeys,
    required this.enableSmsSync,
    this.appPassword,
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
    String? tagRules,
    String? smsRules,
    String? historyWindowHotKeys,
    int? heartbeatInterval,
    String? fileStorePath,
    bool? saveToPictures,
    bool? ignoreShizuku,
    bool? useAuthentication,
    int? appRevalidateDuration,
    String? appPassword,
    String? syncFileHotKeys,
    bool? enableSmsSync,
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
      tagRules: tagRules ?? this.tagRules,
      smsRules: smsRules ?? this.smsRules,
      historyWindowHotKeys: historyWindowHotKeys ?? this.historyWindowHotKeys,
      syncFileHotKeys: syncFileHotKeys ?? this.syncFileHotKeys,
      heartbeatInterval: heartbeatInterval ?? this.heartbeatInterval,
      fileStorePath:
          Directory(fileStorePath ?? this.fileStorePath).absolute.normalizePath,
      saveToPictures: saveToPictures ?? this.saveToPictures,
      ignoreShizuku: ignoreShizuku ?? this.ignoreShizuku,
      useAuthentication: useAuthentication ?? this.useAuthentication,
      appRevalidateDuration:
          appRevalidateDuration ?? this.appRevalidateDuration,
      appPassword: appPassword ?? this.appPassword,
      enableSmsSync: enableSmsSync ?? this.enableSmsSync,
    );
  }
}
