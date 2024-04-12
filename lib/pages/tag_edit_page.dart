import 'dart:io';
import 'dart:math';

import 'package:clipshare/db/app_db.dart';
import 'package:clipshare/entity/tables/history_tag.dart';
import 'package:clipshare/entity/views/v_history_tag_hold.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/provider/history_tag_provider.dart';
import 'package:clipshare/util/extension.dart';
import 'package:clipshare/util/log.dart';
import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';

import '../util/constants.dart';

class TagEditPage extends StatefulWidget {
  final int hisId;

  const TagEditPage(this.hisId, {super.key});

  static void goto(int hisId) {
    var showLeftBar =
        MediaQuery.of(App.context).size.width >= Constants.showLeftBarWidth;
    if (showLeftBar || PlatformExt.isPC) {
      showDialog(
        context: App.context,
        builder: (context) {
          var h = MediaQuery.of(context).size.height;
          return Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 350,
                maxHeight: min(h * 0.7, 350 * 1.618),
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: TagEditPage(hisId),
            ),
          );
        },
      );
    } else {
      Navigator.push(
        App.context,
        MaterialPageRoute(
          builder: (context) => TagEditPage(hisId),
        ),
      );
    }
  }

  @override
  State<TagEditPage> createState() => _TagEditPageState();
}

class _TagEditPageState extends State<TagEditPage> {
  static const tag = "TagEditPage";

  final TextEditingController _textController = TextEditingController();
  final List<VHistoryTagHold> _tags = List.empty(growable: true);
  late List<VHistoryTagHold> _origin;
  final List<VHistoryTagHold> _selected = List.empty(growable: true);
  bool saving = false;
  bool exists = false;

  bool get showLeftBar =>
      MediaQuery.of(App.context).size.width >= Constants.showLeftBarWidth;

  @override
  void initState() {
    super.initState();
    AppDb.inst.historyTagDao.listWithHold(widget.hisId).then((lst) {
      _selected.clear();
      _tags.clear();
      _tags.addAll(lst);
      _selected.addAll(lst.where((v) => v.hasTag));
      //原始值，禁止改变
      _origin = List.of(_selected);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    var appBarTitle = Row(
      children: [
        if (showLeftBar || PlatformExt.isPC)
          const Icon(Icons.tag)
        else
          Container(),
        const Text("编辑标签"),
      ],
    );
    var appBarActions = [
      TextButton(
        onPressed: () {
          setState(() {
            saving = true;
          });
          try {
            var originSet = _origin.toSet();
            var selectedSet = _selected.toSet();
            //原始值 - 选择的值，找出被删除的tag
            var willRmSet = originSet.difference(selectedSet);
            //选择的值 - 原始值，找出应增加的tag
            var willAddSet = selectedSet.difference(originSet);

            var willRmList = List<HistoryTag>.empty(growable: true);
            var willAddList = List<HistoryTag>.empty(growable: true);

            Future<int?> link = Future.value(0);

            ///找出所有需要删除的 tag id
            for (var v in willRmSet) {
              var id = widget.hisId;
              link = link.then((value) {
                //获取原 hisTagId
                return AppDb.inst.historyTagDao.get(id, v.tagName).then((ht) {
                  if (ht == null) return Future.value();
                  willRmList.add(ht);
                  return Future.value();
                });
              });
            }

            ///生成所有需要添加的 tag
            for (var v in willAddSet) {
              var t = HistoryTag(v.tagName, widget.hisId);
              willAddList.add(t);
            }

            ///开始删除
            var notifier = context.ref.notifier(HistoryTagProvider.inst);
            link
                .then((value) => notifier.removeList(willRmList))
                .then((value) => notifier.addList(willAddList))
                .then(
                  (value) => setState(() {
                    saving = false;
                    Navigator.pop(context);
                  }),
                );
          } catch (e, t) {
            setState(() {
              saving = false;
            });
            Log.debug(tag, e);
            Log.debug(tag, t);
          }
        },
        child: saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                ),
              )
            : const Text("保存"),
      ),
    ];
    return Scaffold(
      backgroundColor:
          showLeftBar || PlatformExt.isPC ? Colors.transparent : null,
      appBar: showLeftBar || Platform.isWindows
          ? null
          : AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: appBarTitle,
              actions: appBarActions,
            ),
      body: Column(
        children: [
          showLeftBar || PlatformExt.isPC
              ? Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: DefaultTextStyle(
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.black,
                              fontFamily:
                                  Platform.isWindows ? 'Microsoft YaHei' : null,
                            ),
                            child: appBarTitle,
                          ),
                        ),
                        ...appBarActions,
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          Expanded(
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
                    border: InputBorder.none,
                  ),
                  onChanged: (text) {
                    Log.debug(tag, text);
                    for (var t in _tags) {
                      if (t.tagName == text) {
                        setState(() {
                          exists = true;
                        });
                        return;
                      }
                    }
                    setState(() {
                      exists = false;
                    });
                  },
                ),
                _textController.text.isNotEmpty && !exists
                    ? TextButton(
                        onPressed: () {
                          var text = _textController.text;
                          var tagHold =
                              VHistoryTagHold(widget.hisId, text, true);
                          _tags.add(tagHold);
                          _selected.add(tagHold);
                          setState(() {
                            exists = true;
                          });
                        },
                        child: Text("创建 \"${_textController.text}\" 标签"),
                      )
                    : const SizedBox.shrink(),
                Column(
                  children: [
                    for (var item in _tags)
                      Column(
                        children: [
                          InkWell(
                            onTap: () {},
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 10, right: 5),
                              child: Row(
                                children: [
                                  Text(item.tagName),
                                  const Expanded(child: SizedBox.shrink()),
                                  Checkbox(
                                    value: item.hasTag,
                                    onChanged: (checked) {
                                      if (checked!) {
                                        item.hasTag = true;
                                        _selected.add(item);
                                      } else {
                                        item.hasTag = false;
                                        _selected.remove(item);
                                      }
                                      setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(
                            height: 1,
                            color: Colors.black12,
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
