import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/handlers/guide/base_guide.dart';
import 'package:clipshare/app/utils/permission_helper.dart';
import 'package:clipshare/app/widgets/permission_guide.dart';
import 'package:flutter/material.dart';

class StoragePermGuide extends BaseGuide {
  bool? hasPerm;

  StoragePermGuide() {
    super.widget = PermissionGuide(
      title: TranslationKey.storagePermGuideTitle.tr,
      icon: Icons.storage_outlined,
      description: TranslationKey.storagePermGuideDescription.tr,
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
