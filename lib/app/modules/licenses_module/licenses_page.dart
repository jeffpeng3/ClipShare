import 'package:clipshare/app/modules/licenses_module/licenses_controller.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/widgets/settings/card/setting_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class LicensesPage extends GetView<LicensesController> {
  static const padding = EdgeInsets.all(16);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Licenses')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ListView.separated(
          itemBuilder: (ctx, i) {
            if (i == 0 || i == controller.licenses.length + 1) {
              return const SizedBox(height: 5);
            }
            final item = controller.licenses[i - 1];
            return SettingCard(
              borderRadius: BorderRadius.circular(8),
              title: Text(item['name'].toString()),
              description: Chip(
                label: Text(
                  item['license'].toString(),
                  style: const TextStyle(fontSize: 12),
                ),
                visualDensity: const VisualDensity(
                  horizontal: VisualDensity.minimumDensity,
                  vertical: VisualDensity.minimumDensity,
                ),
                side: BorderSide.none,
                padding: const EdgeInsets.all(0),
              ),
              value: item['url'].toString(),
              action: (v) {
                return IconButton(
                  onPressed: () {
                    if (PlatformExt.isDesktop) {
                      v.openUrl();
                    } else {
                      v.askOpenUrl();
                    }
                  },
                  icon: const Icon(Icons.link),
                );
              },
            );
          },
          separatorBuilder: (ctx, i) => const SizedBox(
            height: 5,
          ),
          itemCount: controller.licenses.length + 2,
        ),
      ),
    );
  }
}
