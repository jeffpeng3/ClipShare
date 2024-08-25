import 'package:clipshare/app/services/tag_service.dart';
import 'package:clipshare/app/widgets/pages/tag_edit_page.dart';
import 'package:clipshare/app/widgets/rounded_chip.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClipTagRowView extends StatefulWidget {
  final int hisId;
  final Color? clipBgColor;

  const ClipTagRowView({super.key, required this.hisId, this.clipBgColor});

  @override
  State<StatefulWidget> createState() {
    return _ClipTagRowViewState();
  }
}

class _ClipTagRowViewState extends State<ClipTagRowView> {
  final tagService = Get.find<TagService>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Obx(
        () {
          var tags = tagService.getTagList(widget.hisId);
          return Row(
            children: [
              for (var tag in tags)
                Container(
                  margin: const EdgeInsets.only(left: 5),
                  child: RoundedChip(
                    backgroundColor: widget.clipBgColor,
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
                      tag,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  TagEditPage.goto(widget.hisId);
                },
                icon: const Row(
                  children: [
                    Text("标签"),
                    Icon(
                      Icons.add,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
