import 'package:clipshare/app/utils/log.dart';

enum ForwardMsgType {
  //中转模式已准备好
  forwardReady,
  //中转已经连接
  alreadyConnected,
  //中转双方已连接
  bothConnected,
  //未知key
  unknown;

  static ForwardMsgType getValue(String name) =>
      ForwardMsgType.values.firstWhere(
        (e) => e.name == name,
        orElse: () {
          Log.debug("TransferMsgType", "key '$name' unknown");
          return ForwardMsgType.unknown;
        },
      );
}
