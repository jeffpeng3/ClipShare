import 'package:clipshare/db/db_util.dart';
import 'package:clipshare/entity/tables/history_tag.dart';
import 'package:clipshare/entity/views/v_history_tag_hold.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/util/log.dart';
import 'package:flutter/material.dart';

import '../entity/tables/operation_record.dart';
import '../util/constants.dart';

class TagEditPage extends StatefulWidget {
  final int hisId;

  const TagEditPage(this.hisId, {super.key});

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

  @override
  void initState() {
    super.initState();
    DBUtil.inst.historyTagDao.listWithHold(widget.hisId).then((lst) {
      Log.debug(tag, lst);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("编辑标签"),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                saving = true;
              });
              try {
                var originSet = _origin.toSet();
                var selectedSet = _selected.toSet();
                //原始值 - 选择的值，找出被删除的tag
                var willRmList = originSet.difference(selectedSet);
                //选择的值 - 原始值，找出应增加的tag
                var willAddList = selectedSet.difference(originSet);

                ///增加
                Future<int?> link = Future.value(0);
                for (var v in willAddList) {
                  var id = App.snowflake.nextId();
                  var t = HistoryTag(id, v.tagName, widget.hisId);
                  //链式处理
                  link = link.then((value) {
                    return DBUtil.inst.historyTagDao.add(t).then((res) {
                      if (res <= 0) return Future.value();
                      var opRecord = OperationRecord(
                        id: App.snowflake.nextId(),
                        uid: App.userId,
                        module: Module.tag,
                        method: OpMethod.add,
                        data: t.id.toString(),
                      );
                      //添加操作记录
                      return DBUtil.inst.opRecordDao.addAndNotify(opRecord);
                    });
                  });
                }

                ///删除
                for (var v in willRmList) {
                  var id = widget.hisId;
                  link = link.then((value) {
                    //获取原 hisTagId
                    return DBUtil.inst.historyTagDao
                        .get(id, v.tagName)
                        .then((ht) {
                      if (ht == null) return Future.value();
                      //删除tag
                      return DBUtil.inst.historyTagDao
                          .remove(id, v.tagName)
                          .then((res) {
                        if (res == null || res <= 0) return Future.value();
                        var opRecord = OperationRecord(
                          id: App.snowflake.nextId(),
                          uid: App.userId,
                          module: Module.tag,
                          method: OpMethod.delete,
                          data: ht.id.toString(),
                        );
                        //添加操作记录
                        return DBUtil.inst.opRecordDao.addAndNotify(opRecord);
                      });
                    });
                  });
                }
                link.then((value) {
                  setState(() {
                    saving = false;
                  });
                  Navigator.pop(context);
                });
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
        ],
      ),
      body: Container(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 0),
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
                      var tagHold = VHistoryTagHold(widget.hisId, text, true);
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
                          padding: const EdgeInsets.only(left: 10, right: 5),
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
                                  Log.debug(tag, "${item.tagName} $checked");
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
    );
  }
}
