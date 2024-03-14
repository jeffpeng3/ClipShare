import 'package:clipshare/components/permission_guide.dart';
import 'package:clipshare/handler/permission_handler.dart';
import 'package:clipshare/pages/guide/base_guide.dart';
import 'package:flutter/material.dart';

class BatteryPermGuide extends BaseGuide {
  var permHandler = IgnoreBatteryHandler();

  BatteryPermGuide() {
    super.widget = PermissionGuide(
      title: "电池优化",
      icon: Icons.filter_none_rounded,
      description: "为了保证后台存活需要将其从电池优化中移除",
      grantPerm: permHandler.request,
    );
  }

  @override
  Future<bool> canNext() async {
    return permHandler.hasPermission();
  }
}
