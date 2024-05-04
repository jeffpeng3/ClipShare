import 'package:clipshare/components/permission_guide.dart';
import 'package:clipshare/pages/guide/base_guide.dart';
import 'package:clipshare/util/permission_helper.dart';
import 'package:flutter/material.dart';

class StoragePermGuide extends BaseGuide {
  bool? hasPerm;

  StoragePermGuide() {
    super.widget = PermissionGuide(
      title: "存储权限",
      icon: Icons.storage_outlined,
      description: "同步图片与文件时需要存储权限，否则无法保存文件。",
      grantPerm: PermissionHelper.reqAndroidStoragePerm,
      checkPerm: canNext,
    );
    canNext().then((has) {
      hasPerm = has;
    });
  }

  @override
  Future<bool> canNext() async {
    return PermissionHelper.testAndroidStoragePerm();
  }
}
