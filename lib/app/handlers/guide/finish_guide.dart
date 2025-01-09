import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/handlers/guide/base_guide.dart';
import 'package:clipshare/app/widgets/permission_guide.dart';
import 'package:flutter/material.dart';

class FinishGuide extends BaseGuide {
  bool? hasPerm;

  FinishGuide() {
    super.widget = PermissionGuide(
      title: TranslationKey.completed.tr,
      icon: Icons.check_circle,
      description: TranslationKey.completedGuideTitleDescription.tr,
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
