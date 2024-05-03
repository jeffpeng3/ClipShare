import 'dart:convert';

import 'package:clipshare/components/clip_simple_data_content.dart';
import 'package:clipshare/components/clip_simple_data_extra_info.dart';
import 'package:clipshare/components/rounded_chip.dart';
import 'package:clipshare/entity/clip_data.dart';
import 'package:clipshare/util/global.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';

///多窗口下一些数据拿不到所以单独写一个
class ClipDataCardCompact extends StatelessWidget {
  final String devName;
  final ClipData _clip;

  const ClipDataCardCompact({
    super.key,
    required ClipData clip,
    required this.devName,
  }) : _clip = clip;

  @override
  Widget build(BuildContext context) {
    var isDouble = false;
    return SizedBox(
      height: 150,
      child: Card(
        elevation: 0,
        child: InkWell(
          mouseCursor: SystemMouseCursors.basic,
          onTap: () {
            if (isDouble) {
              DesktopMultiWindow.invokeMethod(
                0,
                'copy',
                jsonEncode({"id": _clip.data.id}),
              ).then(
                (args) => Global.snackBarSuc(context, "复制成功"),
              );
              isDouble = false;
            } else {
              isDouble = true;
              Future.delayed(const Duration(milliseconds: 300), () {
                isDouble = false;
              });
            }
          },
          onSecondaryTap: () {
            print("右键");
          },
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    RoundedChip(
                      avatar: const Icon(Icons.devices_rounded),
                      backgroundColor: const Color(0x1a000000),
                      label: Text(
                        devName,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: ClipSimpleDataContent(
                    clip: _clip,
                  ),
                ),
                ClipSimpleDataExtraInfo(clip: _clip),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
