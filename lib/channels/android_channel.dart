import 'package:clipshare/main.dart';

class AndroidChannel {
  /// 通知 Android 媒体库刷新
  ///
  static void notifyMediaScan(String path) {
    App.androidChannel.invokeMethod("notifyMediaScan", {
      "imagePath": path,
    });
  }
}
