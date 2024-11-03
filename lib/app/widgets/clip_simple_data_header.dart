import 'package:clipshare/app/data/repository/entity/clip_data.dart';
import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/services/device_service.dart';
import 'package:clipshare/app/services/tag_service.dart';
import 'package:clipshare/app/widgets/clip_tag_row_view.dart';
import 'package:clipshare/app/widgets/rounded_chip.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

///历史记录中的卡片显示的额外信息部分，如时间，大小等
class ClipSimpleDataHeader extends StatelessWidget {
  final ClipData clip;
  final bool routeToSearchOnClickChip;
  final devService = Get.find<DeviceService>();
  final tagService = Get.find<TagService>();
  final homeController = Get.find<HomeController>();

  ClipSimpleDataHeader({
    super.key,
    required this.clip,
    required this.routeToSearchOnClickChip,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        //来源设备
        RoundedChip(
          avatar: const Icon(Icons.devices_rounded),
          // backgroundColor: const Color(0x1a000000),
          onPressed: () {
            if (routeToSearchOnClickChip) {
              //导航至搜索页面
              homeController.gotoSearchPage(
                clip.data.devId,
                null,
              );
            }
          },
          label: Obx(
            () => Text(
              devService.getName(clip.data.devId),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        //标签
        ClipTagRowView(
          hisId: clip.data.id,
          clipBgColor: const Color(0x1a000000),
          routeToSearchOnClickChip: routeToSearchOnClickChip,
        ),
      ],
    );
  }
}
