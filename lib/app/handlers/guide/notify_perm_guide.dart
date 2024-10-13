import 'package:clipshare/app/handlers/guide/base_guide.dart';
import 'package:clipshare/app/handlers/permission_handler.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/permission_guide.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotifyPermGuide extends BaseGuide {
  var permHandler = NotifyPermHandler();
  bool? hasPerm;
  final androidChannelService = Get.find<AndroidChannelService>();

  NotifyPermGuide() {
    super.widget = PermissionGuide(
      title: "通知权限",
      icon: Icons.notifications_active_outlined,
      description: "开启通知，以启动前台服务",
      grantPerm: permHandler.request,
      checkPerm: canNext,
    );
    canNext().then((has) {
      hasPerm = has;
    });
  }

  @override
  Future<bool> canNext() async {
    var has = await permHandler.hasPermission();
    hasPerm = has;
    return has;
  }
}
