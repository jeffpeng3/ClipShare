import 'dart:io';

import 'package:clipshare/app/data/repository/entity/clip_data.dart';
import 'package:clipshare/app/modules/views/preview_page.dart';
import 'package:clipshare/app/utils/extension.dart';
import 'package:flutter/material.dart';

///历史记录中的卡片显示的内容
class ClipSimpleDataContent extends StatelessWidget {
  final ClipData clip;

  const ClipSimpleDataContent({super.key, required this.clip});

  @override
  Widget build(BuildContext context) {
    if (clip.isText || clip.isSms) {
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
    if (clip.isFile) {
      return Row(
        children: [
          const Icon(
            Icons.file_present_outlined,
            color: Colors.blue,
          ),
          const SizedBox(
            width: 5,
          ),
          Expanded(child: Text(clip.data.content)),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
