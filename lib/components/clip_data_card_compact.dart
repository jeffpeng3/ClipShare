import 'dart:convert';

import 'package:clipshare/components/rounded_chip.dart';
import 'package:clipshare/entity/clip_data.dart';
import 'package:clipshare/util/global.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';

class ClipDataCardCompact extends StatelessWidget {
  final String devName;
  final ClipData _clip;

  const ClipDataCardCompact(
      {super.key, required ClipData clip, required this.devName})
      : _clip = clip;

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
                    )
                  ],
                ),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _clip.data.content,
                          textAlign: TextAlign.left,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _clip.data.top
                        ? const Icon(Icons.push_pin, size: 16)
                        : const SizedBox(width: 0),
                    !_clip.data.sync
                        ? const Icon(
                            Icons.sync,
                            size: 16,
                            color: Colors.red,
                          )
                        : const SizedBox(width: 0),
                    Text(_clip.timeStr),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 10),
                    ),
                    Text(_clip.sizeText),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
