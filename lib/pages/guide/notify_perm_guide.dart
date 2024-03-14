import 'package:clipshare/components/permission_guide.dart';
import 'package:clipshare/handler/permission_handler.dart';
import 'package:clipshare/pages/guide/base_guide.dart';
import 'package:flutter/material.dart';

class NotifyPermGuide extends BaseGuide {
  var permHandler = NotifyPermHandler();

  NotifyPermGuide() {
    super.allowSkip = true;
    super.widget = PermissionGuide(
      title: "通知权限",
      icon: Icons.notifications_active_outlined,
      description: "开启通知，以接收重要消息",
      grantPerm: permHandler.request,
    );
  }

  @override
  Future<bool> canNext() async {
    return permHandler.hasPermission();
  }
}
