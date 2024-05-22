import 'package:clipshare/main.dart';

class ClipChannelMethod {
  ClipChannelMethod._private();

  static const onClipboardChanged = "onClipboardChanged";
  static const getHistory = "getHistory";
  static const copy = "copy";
}

class ClipChannel {
  ClipChannel._private();

  ///复制内容到剪贴板
  static Future<bool?> copy(dynamic data) {
    return App.clipChannel.invokeMethod<bool>(ClipChannelMethod.copy, data);
  }
}
