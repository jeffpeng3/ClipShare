import 'package:clipshare/app/data/repository/entity/clip_data.dart';
import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/services/device_service.dart';
import 'package:clipshare/app/services/tag_service.dart';
import 'package:clipshare/app/widgets/rounded_chip.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

///历史记录中的卡片显示的额外信息部分，如时间，大小等
class ClipSimpleDataHeader extends StatefulWidget {
  final ClipData clip;
  final bool routeToSearchOnClickChip;

  const ClipSimpleDataHeader({
    super.key,
    required this.clip,
    required this.routeToSearchOnClickChip,
  });

  @override
  State<StatefulWidget> createState() {
    return _ClipSimpleDataExtraInfoState();
  }
}

class _ClipSimpleDataExtraInfoState extends State<ClipSimpleDataHeader> {
  final devService = Get.find<DeviceService>();
  final tagService = Get.find<TagService>();
  final homeController = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    var tags = tagService.getTagList(widget.clip.data.id);
    return Row(
      children: [
        //来源设备
        RoundedChip(
          avatar: const Icon(Icons.devices_rounded),
          backgroundColor: const Color(0x1a000000),
          onPressed: () {
            if (widget.routeToSearchOnClickChip) {
              //导航至搜索页面
              homeController.gotoSearchPage(
                widget.clip.data.devId,
                null,
              );
            }
          },
          label: Obx(
            () => Text(
              devService.getName(widget.clip.data.devId),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        //标签
        for (var tagName in tags)
          Container(
            margin: const EdgeInsets.only(left: 5),
            child: RoundedChip(
              onPressed: () {
                if (widget.routeToSearchOnClickChip) {
                  //导航至搜索页面
                  homeController.gotoSearchPage(null, tagName);
                }
              },
              backgroundColor: const Color(0x1a000000),
              avatar: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(
                  '#',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
              label: Text(
                tagName,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
