import 'dart:io';

import 'package:clipshare/app/modules/debug_module/debug_controller.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/base/custom_title_bar_layout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class DebugPage extends GetView<DebugController> {
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final pageTag = "DebugPage";

  @override
  Widget build(BuildContext context) {
    return CustomTitleBarLayout(
      child: TextButton(
          onPressed: () async {
            var uri = "content://media/external/images/media/1000000431";
            final androidChannelService = Get.find<AndroidChannelService>();
            final path = await androidChannelService.getLatestImagePath();
            print(uri);
            Log.debug(pageTag, "path");
            var file = File(path!);
            final time = file.lastModifiedSync();
            Log.debug(pageTag, "$path $time");
          },
          child: Text("test uri")),
      children: [],
    );
  }
}
