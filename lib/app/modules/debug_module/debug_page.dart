import 'package:clipshare/app/modules/debug_module/debug_controller.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/widgets/environment_selection_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class DebugPage extends GetView<DebugController> {
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();

  @override
  Widget build(BuildContext context) {
    return Column(
      // mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnvironmentSelectionCard(
          selected: controller.selected.value,
          onTap: () {
            controller.selected.value = !controller.selected.value;
          },
          icon: Image.asset(
            Constants.shizukuLogoPath,
            width: 48,
            height: 48,
          ),
          tipContent: const Row(
            children: [
              Text(
                "Shizuku 模式",
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(
                width: 5,
              ),
              Icon(
                Icons.info_outline,
                color: Colors.blueGrey,
                size: 16,
              ),
            ],
          ),
          tipDesc: const Text(
            "无需 Root，需要安装 Shizuku，重启手机后需要重新激活",
            style: TextStyle(fontSize: 12, color: Color(0xff6d6d70)),
          ),
        ),
        EnvironmentSelectionCard(
          selected: false,
          onTap: () {
            controller.selected.value = !controller.selected.value;
          },
          icon: Image.asset(
            Constants.rootLogoPath,
            width: 48,
            height: 48,
          ),
          tipContent: const Text(
            "Root模式",
            style: TextStyle(
              color: Colors.blueGrey,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          tipDesc: const Text(
            "以 Root 权限启动，重启手机无需重新激活",
            style: TextStyle(fontSize: 12, color: Color(0xff6d6d70)),
          ),
        ),
        EnvironmentSelectionCard(
          selected: false,
          onTap: () {
            controller.selected.value = !controller.selected.value;
          },
          icon: const Icon(
            Icons.block_outlined,
            size: 40,
            color: Colors.blueGrey,
          ),
          tipContent: const Text(
            "忽略",
            style: TextStyle(
              color: Colors.blueGrey,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          tipDesc: const Text(
            "剪贴板将无法后台监听，只能被动同步",
            style: TextStyle(fontSize: 12, color: Color(0xff6d6d70)),
          ),
        ),
      ],
    );
  }
}
