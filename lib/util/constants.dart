import 'package:clipshare/util/print_util.dart';

class Constants {
  static const int port = 42317;
  static const String multicastGroup = '224.0.0.128';
  static const heartbeatsSeconds = 10;

  //配对时限（秒）
  static const pairingLimit = 60;
}

enum MsgKey {
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
  unknown;

  static MsgKey getValue(String name) =>
      MsgKey.values.firstWhere((e) => e.name == name, orElse: () {
        PrintUtil.debug("MsgKey", "key '$name' unknown");
        return MsgKey.unknown;
      });
}
