import 'package:clipshare/components/permission_guide.dart';
import 'package:clipshare/pages/guide/base_guide.dart';
import 'package:flutter/material.dart';

class FinishGuide extends BaseGuide {
  bool? hasPerm;

  FinishGuide() {
    super.widget = PermissionGuide(
      title: "已完成",
      icon: Icons.check_circle,
      description: "已完成全部设置",
      grantPerm: null,
      checkPerm: canNext,
    );
    canNext().then((has) {
      hasPerm = has;
    });
  }

  @override
  Future<bool> canNext() async {
    return true;
  }
}
