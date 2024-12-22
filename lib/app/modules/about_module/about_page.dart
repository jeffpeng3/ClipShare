import 'package:clipshare/app/modules/about_module/about_controller.dart';
import 'package:clipshare/app/routes/app_pages.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/widgets/check_update_button.dart';
import 'package:clipshare/app/widgets/settings/card/setting_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class AboutPage extends GetView<AboutController> {
  static const topBorderRadius = BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(16),
  );
  static const bottomBorderRadius = BorderRadius.only(
    bottomLeft: Radius.circular(16),
    bottomRight: Radius.circular(16),
  );
  static const padding = EdgeInsets.all(16);
  static const fontSize = TextStyle(fontSize: 16);

  @override
  Widget build(BuildContext context) {
    final appConfig = Get.find<ConfigService>();
    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SettingCard(
                borderRadius: topBorderRadius,
                padding: padding,
                title: const Row(
                  children: [
                    Icon(
                      Icons.help_outline_outlined,
                      color: Colors.blueGrey,
                      size: 28,
                    ),
                    SizedBox(
                      width: 16,
                    ),
                    Text(
                      "使用说明",
                      style: fontSize,
                    ),
                  ],
                ),
                value: null,
                onTap: () {
                  if (PlatformExt.isDesktop) {
                    Constants.usageWeb.openUrl();
                  } else {
                    Constants.usageWeb.askOpenUrl();
                  }
                },
              ),
              SettingCard(
                padding: padding,
                onTap: () {
                  Get.toNamed(Routes.LICENSES);
                },
                title: const Row(
                  children: [
                    Icon(
                      Icons.event_note_outlined,
                      color: Colors.blueGrey,
                      size: 28,
                    ),
                    SizedBox(
                      width: 16,
                    ),
                    Text(
                      "Licenses",
                      style: fontSize,
                    ),
                  ],
                ),
                value: null,
              ),
              SettingCard(
                padding: padding,
                title: Row(
                  children: [
                    Icon(
                      MdiIcons.github,
                      color: Colors.blueGrey,
                      size: 28,
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    const Text(
                      "Github",
                      style: fontSize,
                    ),
                  ],
                ),
                value: null,
                onTap: () {
                  if (PlatformExt.isDesktop) {
                    Constants.githubRepo.openUrl();
                  } else {
                    Constants.githubRepo.askOpenUrl();
                  }
                },
              ),
              SettingCard(
                padding: padding,
                title: Row(
                  children: [
                    Icon(
                      MdiIcons.qqchat,
                      color: Colors.blueGrey,
                      size: 28,
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    const Text(
                      "加入QQ群",
                      style: fontSize,
                    ),
                  ],
                ),
                value: null,
                onTap: () {
                  Constants.qqGroup.openUrl();
                },
              ),
              SettingCard(
                padding: padding,
                title: Row(
                  children: [
                    Icon(
                      MdiIcons.web,
                      color: Colors.blueGrey,
                      size: 28,
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    const Text(
                      "查看官网",
                      style: fontSize,
                    ),
                  ],
                ),
                value: null,
                onTap: () {
                  if (PlatformExt.isDesktop) {
                    Constants.clipshareSite.openUrl();
                  } else {
                    Constants.clipshareSite.askOpenUrl();
                  }
                },
              ),
              SettingCard(
                padding: padding,
                title: Row(
                  children: [
                    Icon(
                      MdiIcons.update,
                      color: Colors.blueGrey,
                      size: 28,
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    const Text(
                      "更新日志",
                      style: fontSize,
                    ),
                  ],
                ),
                value: null,
                onTap: () {
                  Get.toNamed(Routes.UPDATE_LOG);
                },
              ),
              SettingCard(
                borderRadius: bottomBorderRadius,
                padding: padding,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blueGrey,
                      size: 28,
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "软件版本",
                          style: fontSize,
                        ),
                        Text(
                          appConfig.version.toString(),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
                action: (v) {
                  return const CheckUpdateButton();
                },
                value: null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
