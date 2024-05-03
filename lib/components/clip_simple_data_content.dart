import 'dart:io';

import 'package:clipshare/entity/clip_data.dart';
import 'package:clipshare/pages/preview_page.dart';
import 'package:clipshare/util/extension.dart';
import 'package:flutter/material.dart';

///历史记录中的卡片显示的内容
class ClipSimpleDataContent extends StatelessWidget {
  final ClipData clip;

  const ClipSimpleDataContent({super.key, required this.clip});

  @override
  Widget build(BuildContext context) {
    if (clip.isText) {
      return Text(
        clip.data.content.substringMinLen(0, 200),
        textAlign: TextAlign.left,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      );
    }
    if (clip.isImage) {
      return MouseRegion(
        cursor:
            PlatformExt.isMobile ? SystemMouseCursors.click : MouseCursor.defer,
        child: InkWell(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(
              File(clip.data.content),
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PreviewPage(
                  clip: clip,
                ),
              ),
            );
          },
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
