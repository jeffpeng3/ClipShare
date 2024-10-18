import 'package:clipboard_listener/clipboard_manager.dart';
import 'package:clipboard_listener/enums.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ClipChannelMethod {
  ClipChannelMethod._private();

  static const getHistory = "getHistory";
  static const setTop = "setTop";
  static const ignoreNextCopy = "ignoreNextCopy";
}

class ClipChannelService extends GetxService {
  late final MethodChannel clipChannel;

  ClipChannelService init() {
    final appConfig = Get.find<ConfigService>();
    clipChannel = appConfig.clipChannel;
    return this;
  }

  ///复制内容到剪贴板
  Future<bool?> setTop(int id, bool top) {
    final data = {"id": id, "top": top};
    return clipChannel.invokeMethod<bool>(ClipChannelMethod.setTop, data);
  }
}
