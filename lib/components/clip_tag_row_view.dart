import 'package:clipshare/components/rounded_chip.dart';
import 'package:clipshare/db/db_util.dart';
import 'package:flutter/material.dart';

import '../pages/tag_edit_page.dart';

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
  List<String> _tags = [];

  void initTags() {
    DBUtil.inst.historyTagDao.list(widget.hisId).then((lst) {
      _tags = lst.map((e) => e.tagName).toList();
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void initState() {
    super.initState();
    initTags();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var tag in _tags)
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
              TagEditPage.goto(widget.hisId).then((value) {
                initTags();
              });
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
      ),
    );
  }
}
