import 'dart:convert';

import 'package:clipshare/app/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class Constants {
  Constants._private();

  //组播默认端口
  static const int port = 42317;

  //app名称
  static const String appName = "ClipShare";

  //默认窗体大小
  static const String defaultWindowSize = "1000x650";

  //组播地址
  static const String multicastGroup = '224.0.0.128';

  //组播心跳时长
  static const heartbeatInterval = 30;

  //中转程序下载地址
  static const forwardDownloadUrl = "http://www.coclyun.top";

  //默认标签规则
  static final defaultTagRules = jsonEncode(
    {
      "version": 1,
      "data": [
        {
          "name": "链接",
          "rule": r"[a-zA-z]+://[^\s]*",
        }
      ],
    },
  );

  //默认短信规则
  static final defaultSmsRules = jsonEncode(
    {
      "version": 0,
      "data": [],
    },
  );

  //默认历史弹窗快捷键（Ctrl + Alt + H）
  static const defaultHistoryWindowKeys = "458976,458978;458763";

  //文件同步快捷键（Ctrl + Shift + C）
  static const defaultSyncFileHotKeys = "458976,458977;458758";

  static const androidRootStoragePath = "/storage/emulated/0";
  static const androidDownloadPath = "$androidRootStoragePath/Download";
  static const androidPicturesPath = "$androidRootStoragePath/Pictures";

  //配对时限（秒）
  static const pairingLimit = 60;
  static const channelCommon = "top.coclyun.clipshare/common";
  static const channelClip = "top.coclyun.clipshare/clip";
  static const channelAndroid = "top.coclyun.clipshare/android";

  static const smallScreenWidth = 640.0;
  static const showHistoryRightWidth = 840.0;
  static const logoPngPath = "assets/images/logo/logo.png";
  static const logoIcoPath = "assets/images/logo/logo.ico";

  //设备类型图片
  static final Map<String, Icon> devTypeIcons = {
    'Windows': const Icon(
      Icons.laptop_windows_outlined,
      color: Colors.grey,
      size: 48,
    ),
    'Android': const Icon(
      Icons.android_outlined,
      color: Colors.grey,
      size: 48,
    ),
    'Mac': const Icon(
      Icons.laptop_mac_outlined,
      color: Colors.grey,
      size: 48,
    ),
    'Linux': Icon(
      MdiIcons.linux,
      color: Colors.grey,
      size: 48,
    ),
    'IOS': const Icon(
      Icons.apple_outlined,
      color: Colors.grey,
      size: 48,
    ),
  };

  //按键名称映射
  static final keyNameMap = [
    {
      "key": "Divide",
      "name": "/",
    },
    {
      "key": "Multiply",
      "name": "*",
    },
    {
      "key": "Subtract",
      "name": "-",
    },
    {
      "key": "Add",
      "name": "+",
    },
    {
      "key": "Equal",
      "name": "=",
    },
    {
      "key": "Minus",
      "name": "-",
    },
  ];
}

enum Option { add, delete, update }

enum ContentType {
  unknown(label: "未知", value: "unknown", order: 9999),
  all(label: "全部", value: "", order: 9999),
  text(label: "文本", value: "Text", order: 1),
  image(label: "图片", value: "Image", order: 2),
  richText(label: "富文本", value: "RichText", order: 3),
  sms(label: "短信", value: "Sms", order: 4),
  file(label: "文件", value: "File", order: 5);

  const ContentType({
    required this.label,
    required this.value,
    required this.order,
  });

  final String value;
  final String label;
  final int order;

  static ContentType parse(String value) => ContentType.values.firstWhere(
        (e) => e.value == value,
        orElse: () {
          Log.debug("ContentType", "key '$value' unknown");
          return ContentType.unknown;
        },
      );

  static Map<String, String> get typeMap {
    var lst =
        ContentType.values.where((e) => e != ContentType.unknown).toList();
    Map<String, String> res = {};
    for (var t in lst) {
      res[t.label] = t.value;
    }
    return res;
  }
}

enum MsgType {
  //设备连接
  connect,
  //同步确认
  ackSync,
  //在线数据同步
  sync,
  //广播信息
  broadcastInfo,
  //请求配对（生成配对码）
  reqPairing,
  //请求配对（验证配对码）
  pairing,
  //取消配对
  cancelPairing,
  //设备配对成功
  paired,
  //设置置顶（或非置顶）
  setTop,
  //请求缺失数据
  reqMissingData,
  //同步缺失数据
  missingData,
  //删除记录
  rmHistory,
  //配对情况
  pairedStatus,
  //手动断开连接
  disConnect,
  //忘记设备
  forgetDev,
  //心跳
  heartbeat,
  //文件同步
  file,
  //未知key
  unknown;

  static MsgType getValue(String name) => MsgType.values.firstWhere(
        (e) => e.name == name,
        orElse: () {
          Log.debug("MsgKey", "key '$name' unknown");
          return MsgType.unknown;
        },
      );
}

enum OpMethod {
  add,
  delete,
  update,
  unknown;

  static OpMethod getValue(String name) => OpMethod.values.firstWhere(
        (e) => e.name == name,
        orElse: () {
          Log.debug("OpMethod", "key '$name' unknown");
          return OpMethod.unknown;
        },
      );
}

enum Rule {
  tag,
  sms,
  unknown;

  static Rule getValue(String name) => Rule.values.firstWhere(
        (e) => e.name == name,
        orElse: () {
          Log.debug("Rule", "key '$name' unknown");
          return Rule.unknown;
        },
      );
}

enum Module {
  unknown(moduleName: "未知"),
  device(moduleName: "设备管理"),
  tag(moduleName: "标签管理"),
  history(moduleName: "历史记录"),
  rules(moduleName: "规则设置"),
  historyTop(moduleName: "历史记录置顶");

  const Module({required this.moduleName});

  final String moduleName;

  static Module getValue(String name) => Module.values.firstWhere(
        (e) => e.moduleName == name,
        orElse: () {
          Log.debug("Module", "key '$name' unknown");
          return Module.unknown;
        },
      );
}
