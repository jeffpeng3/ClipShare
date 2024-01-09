import 'dart:async';

import 'package:clipshare/components/round_chip.dart';
import 'package:clipshare/db/db_util.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/pages/tag_edit_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../entity/clip_data.dart';
import '../entity/tables/history_tag.dart';

class ClipDetailDialog extends StatefulWidget {
  final ClipData clip;

  const ClipDetailDialog({required this.clip, super.key});

  @override
  State<StatefulWidget> createState() {
    return ClipDetailDialogState();
  }
}

class ClipDetailDialogState extends State<ClipDetailDialog> {
  bool _copy = false;
  List<HistoryTag> _tags = List.empty(growable: true);

  @override
  void initState() {
    super.initState();
    initTags();
  }

  void initTags() {
    DBUtil.inst.historyTagDao.list(widget.clip.data.id.toString()).then((lst) {
      _tags = lst;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 500),
      padding: const EdgeInsets.only(bottom: 30),
      child: Padding(
          padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    alignment: Alignment.topLeft,
                    padding: const EdgeInsets.only(left: 7, top: 7, bottom: 7),
                    child: const Text(
                      "剪贴板",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.blueGrey,
                        ),
                        onPressed: () {
                          //添加删除记录
                        },
                        tooltip: "删除记录",
                      ),
                      IconButton(
                        icon: Icon(
                          widget.clip.data.top
                              ? Icons.push_pin_outlined
                              : Icons.push_pin,
                          color: Colors.blueGrey,
                        ),
                        onPressed: () {
                          //添加操作记录
                        },
                        tooltip: widget.clip.data.top ? "取消置顶" : "置顶",
                      ),
                      IconButton(
                        icon: _copy
                            ? const Icon(
                                Icons.check,
                                color: Colors.blueGrey,
                              )
                            : const Icon(Icons.copy, color: Colors.blueGrey),
                        onPressed: () {
                          _copy = true;
                          setState(() {});
                          // 创建一个延迟0.5秒执行一次的定时器
                          Future.delayed(const Duration(milliseconds: 500), () {
                            _copy = false;
                            setState(() {});
                          });
                          Clipboard.setData(
                              ClipboardData(text: widget.clip.data.content));
                        },
                        tooltip: "复制内容",
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var tag in _tags)
                          Container(
                            margin: const EdgeInsets.only(right: 5),
                            child: RoundedChip(
                              label: Text(
                                tag.tagName,
                              ),
                            ),
                          ),
                        IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TagEditPage(widget.clip.data.id),
                                ),
                              ).then((value) {
                                initTags();
                              });
                            },
                            icon: const Icon(Icons.add)),
                      ],
                    ),
                  )
                ],
              ),
              Row(
                children: [
                  Expanded(
                      child: Container(
                          constraints: const BoxConstraints(maxHeight: 500),
                          margin: const EdgeInsets.only(top: 10),
                          child: SingleChildScrollView(
                            clipBehavior: Clip.antiAlias,
                            child: Container(
                              alignment: Alignment.topLeft,
                              child: SelectableText(
                                widget.clip.data.content,
                                textAlign: TextAlign.left,
                              ),
                            ),
                          )))
                ],
              )
            ],
          )),
    );
  }
}
