import 'package:clipshare/util/log.dart';
import 'package:flutter/material.dart';

class Constants {
  //组播默认端口
  static const int port = 42317;

  //app名称
  static const String appName = "轻贴";

  //组播地址
  static const String multicastGroup = '224.0.0.128';

  //组播心跳时长
  static const heartbeatsSeconds = 10;

  //配对时限（秒）
  static const pairingLimit = 60;
  static const channelCommon = "top.coclyun.clipshare/common";
  static const channelClip = "top.coclyun.clipshare/clip";
  static const channelAndroid = "top.coclyun.clipshare/android";

  //设备类型图片
  static Map<String, Icon> devTypeIcons = const {
    'Windows': Icon(
      Icons.laptop_windows_outlined,
      color: Colors.grey,
      size: 48,
    ),
    'Android': Icon(
      Icons.phone_android_outlined,
      color: Colors.grey,
      size: 48,
    ),
    'Mac': Icon(
      Icons.laptop_mac_outlined,
      color: Colors.grey,
      size: 48,
    ),
    'Linux': Icon(
      Icons.laptop_windows_outlined,
      color: Colors.grey,
      size: 48,
    ),
    'IOS': Icon(
      Icons.apple_outlined,
      color: Colors.grey,
      size: 48,
    ),
  };
}

enum Option { add, delete, update }

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

enum Module {
  unknown(moduleName: "未知"),
  device(moduleName: "设备管理"),
  tag(moduleName: "标签管理"),
  history(moduleName: "历史记录"),
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
