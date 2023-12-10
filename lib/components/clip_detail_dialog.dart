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
      constraints: const BoxConstraints(maxHeight: 400),
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
                      Timer(const Duration(milliseconds: 500), () {
                        _copy = false;
                        setState(() {});
                      });
                      Clipboard.setData(
                          ClipboardData(text: widget.clip.data.content));
                    },
                  ),
                ],
              ),
              Container(
                  child: const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    RoundedChip(
                      label: Text(
                        "#标签1",
                        style:
                            TextStyle(color: Color.fromRGBO(49, 49, 49, 1.0)),
                      ),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    RoundedChip(
                      label: Text("#标签2"),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    RoundedChip(
                      label: Text("#标签3"),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    RoundedChip(
                      label: Text("#标签4"),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    RoundedChip(
                      label: Text("#标签5"),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    RoundedChip(
                      label: Text("#标签6"),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    RoundedChip(
                      label: Text("#标签7"),
                    ),
                  ],
                ),
              )),
              Container(
                  margin: EdgeInsets.only(top: 10),
                  constraints: const BoxConstraints(maxHeight: 271),
                  child: SingleChildScrollView(
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      alignment: Alignment.topLeft,
                      child: SelectableText(
                        widget.clip.data.content,
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ))
            ],
          )),
    );
  }
}
