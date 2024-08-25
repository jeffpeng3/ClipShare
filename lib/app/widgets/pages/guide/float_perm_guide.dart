import 'package:clipshare/app/handlers/permission_handler.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/widgets/pages/guide/base_guide.dart';
import 'package:clipshare/app/widgets/permission_guide.dart';
import 'package:flutter/material.dart';

class FloatPermGuide extends BaseGuide {
  var permHandler = FloatPermHandler();

  FloatPermGuide() {
    super.widget = PermissionGuide(
      title: "悬浮窗权限",
      icon: Icons.filter_none_rounded,
      description:
          "由于高版本Android系统限制，${Constants.appName}需要通过悬浮窗获取剪贴板焦点，开启悬浮窗后还可以随时从屏幕边缘查看剪贴板历史并进行拖拽选择",
      grantPerm: permHandler.request,
      checkPerm: canNext,
    );
  }

  @override
  Future<bool> canNext() async {
    return permHandler.hasPermission();
  }
}
