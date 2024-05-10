import 'package:clipshare/components/rounded_chip.dart';
import 'package:clipshare/entity/clip_data.dart';
import 'package:clipshare/pages/nav/base_page.dart';
import 'package:clipshare/provider/device_info_provider.dart';
import 'package:clipshare/provider/history_tag_provider.dart';
import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';

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
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder(
      provider: HistoryTagProvider.inst,
      builder: (context, tagsMap) {
        var tags = tagsMap.getTagList(widget.clip.data.id);
        return Row(
          children: [
            //来源设备
            Consumer(
              builder: (context, ref) {
                var vm = ref.watch(DeviceInfoProvider.inst);
                return RoundedChip(
                  avatar: const Icon(Icons.devices_rounded),
                  backgroundColor: const Color(0x1a000000),
                  onPressed: () {
                    if (widget.routeToSearchOnClickChip) {
                      //导航至搜索页面
                      BasePage.pageKey.currentState?.gotoSearchPage(
                        widget.clip.data.devId,
                        null,
                      );
                    }
                  },
                  label: Text(
                    vm.getName(widget.clip.data.devId),
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
            //标签
            for (var tagName in tags)
              Container(
                margin: const EdgeInsets.only(left: 5),
                child: RoundedChip(
                  onPressed: () {
                    if (widget.routeToSearchOnClickChip) {
                      //导航至搜索页面
                      BasePage.pageKey.currentState
                          ?.gotoSearchPage(null, tagName);
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
      },
    );
  }
}
