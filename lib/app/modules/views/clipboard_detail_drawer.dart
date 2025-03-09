import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/models/clip_data.dart';
import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/services/device_service.dart';
import 'package:clipshare/app/widgets/clip_content_view.dart';
import 'package:clipshare/app/widgets/clip_tag_row_view.dart';
import 'package:clipshare/app/widgets/rounded_chip.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClipboardDetailDrawer extends StatelessWidget {
  final BorderRadiusGeometry? detailBorderRadius;
  final ClipData clipData;

  const ClipboardDetailDrawer({super.key, this.detailBorderRadius, required this.clipData});

  @override
  Widget build(BuildContext context) {
    final homeCtl = Get.find<HomeController>();
    final devService = Get.find<DeviceService>();
    final showFullPage = homeCtl.drawerWidth != null && homeCtl.drawerWidth! > 400;
    final fullPageWidth = MediaQuery.of(context).size.width * 0.9;
    return Container(
      decoration: BoxDecoration(
        borderRadius: detailBorderRadius,
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ///标题
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Tooltip(
                      message: TranslationKey.fold.tr,
                      child: IconButton(
                        onPressed: () {
                          homeCtl.closeEndDrawer();
                        },
                        icon: const Icon(
                          Icons.keyboard_double_arrow_right,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: Text(
                        TranslationKey.clipboardContent.tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                Tooltip(
                  message: TranslationKey.close.tr,
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      homeCtl.closeEndDrawer();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),

            ///标签栏
            Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 5),
              child: Row(
                children: [
                  ///来源设备
                  Obx(
                    () => RoundedChip(
                      avatar: const Icon(Icons.devices_rounded),
                      label: Text(
                        devService.getName(clipData.data.devId),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),

                  ///持有标签
                  Expanded(
                    child: ClipTagRowView(
                      // key: _clipTagRowKey,
                      hisId: clipData.data.id,
                      clipBgColor: const Color(0x1a000000),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 0.1),

            ///剪贴板内容
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 5),
                child: ClipContentView(
                  // key: _clipTagRowKey,
                  clipData: clipData,
                ),
              ),
            ),
            const Divider(height: 0.1),

            ///底部操作栏
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Tooltip(
                    message: showFullPage ? TranslationKey.fold.tr : TranslationKey.unfold.tr,
                    child: IconButton(
                      onPressed: () {
                        homeCtl.openEndDrawer(
                          drawer: ClipboardDetailDrawer(clipData: clipData),
                          width: showFullPage ? 400 : fullPageWidth,
                        );
                      },
                      icon: Icon(
                        showFullPage ? Icons.keyboard_double_arrow_right : Icons.keyboard_double_arrow_left,
                      ),
                    ),
                  ),
                  Text(clipData.timeStr),
                  Text(clipData.sizeText),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
