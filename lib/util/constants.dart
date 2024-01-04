import 'package:clipshare/util/log.dart';

class Constants {
  //组播默认端口
  static const int port = 42317;
  //组播地址
  static const String multicastGroup = '224.0.0.128';
  //组播心跳时长
  static const heartbeatsSeconds = 10;
  //配对时限（秒）
  static const pairingLimit = 60;
  static const channelCommon = "common";
  static const channelClip = "clip";
  static const channelAndroid = "android";
}
enum MsgType {
  //设备信息
  devInfo,
  //历史记录
  history,
  //历史记录同步确认
  ackSync,
  //广播信息
  broadcastInfo,
  //请求配对（生成配对码）
  requestPairing,
  //请求配对（验证配对码）
  pairing,
  //设备配对成功
  paired,
  //设置置顶（或非置顶）
  setTop,
  //请求同步缺失数据
  requestSyncMissingData,
  //同步缺失数据
  missingData,
  //删除记录
  rmHistory,
  //未知key
  unknown;

  static MsgType getValue(String name) =>
      MsgType.values.firstWhere((e) => e.name == name, orElse: () {
        Log.debug("MsgKey", "key '$name' unknown");
        return MsgType.unknown;
      });
}
