import 'package:clipshare/db/db_util.dart';
import 'package:clipshare/entity/views/v_history_tag_hold.dart';
import 'package:clipshare/util/print_util.dart';
import 'package:flutter/material.dart';

class TagEditPage extends StatefulWidget {
  final int hisId;

  const TagEditPage(this.hisId, {super.key});

  @override
  State<TagEditPage> createState() => _TagEditPageState();
}

class _TagEditPageState extends State<TagEditPage> {
  static const tag = "TagEditPage";

  final TextEditingController _textController = TextEditingController();
  List<VHistoryTagHold> _tags = List.empty(growable: true);
  final List<VHistoryTagHold> _selected = List.empty(growable: true);
  bool testVar = false;

  @override
  void initState() {
    super.initState();
    DBUtil.inst.historyTagDao.listWithHold(widget.hisId.toString()).then((lst) {
      _tags = lst;
      _selected.clear();
      _selected.addAll(lst.where((v) => v.hasTag));
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("编辑标签"),
        actions: [
          TextButton(
              onPressed: _selected.isEmpty ? null : () {},
              child: const Text("保存"))
        ],
      ),
      body: Container(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 20),
        child: ListView(
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _textController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _textController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  hintText: "搜索或创建标签",
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: InputBorder.none),
              onChanged: (value) {
                PrintUtil.debug(tag, value);
                setState(() {});
              },
            ),
            _textController.text.isNotEmpty
                ? TextButton(
                    onPressed: () {},
                    child: Text("创建 \"${_textController.text}\" 标签"))
                : const SizedBox.shrink(),
            Column(
              children: [
                for (var item in _tags)
                  Column(
                    children: [
                      InkWell(
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10, right: 5),
                          child: Row(
                            children: [
                              Text(item.tagName),
                              const Expanded(child: SizedBox.shrink()),
                              Checkbox(
                                  value: item.hasTag,
                                  onChanged: (checked) {
                                    testVar = checked ?? false;
                                    setState(() {});
                                    PrintUtil.debug(
                                        tag, "${item.tagName} $checked");
                                  })
                            ],
                          ),
                        ),
                      ),
                      const Divider(
                        height: 1,
                        color: Colors.black12,
                      )
                    ],
                  )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
