import 'package:clipshare/components/permission_guide.dart';
import 'package:clipshare/handler/permission_handler.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/pages/guide/base_guide.dart';
import 'package:clipshare/util/log.dart';
import 'package:flutter/material.dart';

class NotifyPermGuide extends BaseGuide {
  var permHandler = NotifyPermHandler();
  bool? hasPerm;

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
    if (has) {
      Log.info("NotifyPermGuide", "androidChannel invoke startService");
      App.androidChannel.invokeMethod("startService");
    }
    hasPerm = has;
    return has;
  }
}
