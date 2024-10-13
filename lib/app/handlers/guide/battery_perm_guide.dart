import 'package:clipshare/app/handlers/guide/base_guide.dart';
import 'package:clipshare/app/handlers/permission_handler.dart';
import 'package:clipshare/app/widgets/permission_guide.dart';
import 'package:flutter/material.dart';

class BatteryPermGuide extends BaseGuide {
  var permHandler = IgnoreBatteryHandler();

  BatteryPermGuide({super.allowSkip = true}) {
    super.widget = PermissionGuide(
      title: "电池优化",
      icon: Icons.filter_none_rounded,
      description: "为了保证后台存活需要将其从电池优化中移除\n"
          "此外，请在后台任务卡片中加锁并手机管家中设置允许自启！\n"
          "若点击[去授权]后无反应，请自行在手机设置中查找相关设置项",
      grantPerm: permHandler.request,
      checkPerm: canNext,
    );
  }

  @override
  Future<bool> canNext() async {
    return permHandler.hasPermission();
  }
}
