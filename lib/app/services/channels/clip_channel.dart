import 'package:clipshare/app/services/config_service.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ClipChannelMethod {
  ClipChannelMethod._private();

  static const onClipboardChanged = "onClipboardChanged";
  static const getHistory = "getHistory";
  static const copy = "copy";
}

class ClipChannelService extends GetxService {
  late final MethodChannel clipChannel;

  ClipChannelService init() {
    final appConfig = Get.find<ConfigService>();
    clipChannel = appConfig.clipChannel;
    return this;
  }

  ///复制内容到剪贴板
  Future<bool?> copy(dynamic data) {
    return clipChannel.invokeMethod<bool>(ClipChannelMethod.copy, data);
  }
}
