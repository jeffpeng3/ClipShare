import 'dart:io';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/utils/extensions/number_extension.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

class DragPendingFileListItem extends StatelessWidget {
  final DropItem item;
  static const borderRadius = 12.0;
  final void Function(DropItem item)? onTap;
  final void Function(DropItem item) onRemove;

  const DragPendingFileListItem({super.key, required this.item, this.onTap, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final path = item.path;
    final isDir = FileSystemEntity.typeSync(path) == FileSystemEntityType.directory;
    var size = "";
    if (!isDir) {
      size = File(path).lengthSync().sizeStr;
    }
    return Card(
      elevation: 0,
      child: InkWell(
        mouseCursor: SystemMouseCursors.basic,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Icon(
                isDir ? Icons.folder_outlined : Icons.file_present_outlined,
                color: Colors.blueGrey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontSize: 17),
                    ),
                    Text(
                      isDir ? TranslationKey.folder.tr : size,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w100),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: TranslationKey.removeFromPendingList.tr,
                child: IconButton(
                  onPressed: () {
                    onRemove(item);
                  },
                  icon: const Icon(Icons.delete),
                ),
              ),
            ],
          ),
        ),
        onTap: () {
          onTap?.call(item);
        },
      ),
    );
  }
}
