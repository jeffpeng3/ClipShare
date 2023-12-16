import 'dart:async';

import 'package:clipshare/components/round_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../entity/clip_data.dart';

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
                        onPressed: () {},
                        tooltip: "删除记录",
                      ),
                      IconButton(
                        icon: Icon(
                          widget.clip.data.top
                              ? Icons.push_pin_outlined
                              : Icons.push_pin,
                          color: Colors.blueGrey,
                        ),
                        onPressed: () {},
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
                      IconButton(
                        icon: Icon(
                          Icons.sync,
                          color: widget.clip.data.sync
                              ? Colors.grey
                              : Colors.blueGrey,
                        ),
                        onPressed: widget.clip.data.sync ? null : () {},
                        tooltip: "同步该记录",
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
                        const RoundedChip(
                          label: Text(
                            "#标签1",
                            style: TextStyle(
                                color: Color.fromRGBO(49, 49, 49, 1.0)),
                          ),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        const RoundedChip(
                          label: Text("#标签2"),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        IconButton(
                            onPressed: () {}, icon: const Icon(Icons.add)),
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
