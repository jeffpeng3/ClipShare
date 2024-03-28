import 'package:clipshare/components/rounded_chip.dart';
import 'package:clipshare/provider/history_tag_provider.dart';
import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';

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
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Consumer(
        builder: (context, ref) {
          var vm = ref.watch(HistoryTagProvider.inst);
          var tags = vm.getTagList(widget.hisId);
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
