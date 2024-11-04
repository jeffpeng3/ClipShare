import 'dart:io';

import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:crypto/crypto.dart' as crypto;

extension DirectoryExt on Directory {
  String get normalizePath {
    if (Platform.isWindows) {
      return absolute.path.replaceAll(RegExp(r'(/+|\\+)'), "\\");
    } else {
      return absolute.path.replaceAll(RegExp(r'(/+|\\+)'), "/");
    }
  }
}

extension FileExt on File {
  String get normalizePath {
    if (Platform.isWindows) {
      return absolute.path.replaceAll(RegExp(r'(/+|\\+)'), "\\");
    } else {
      return absolute.path.replaceAll(RegExp(r'(/+|\\+)'), "/");
    }
  }

  String get fileName {
    return absolute.path
        .replaceFirst(absolute.parent.path, "")
        //去除重复斜杠
        .replaceAll(RegExp(r'(/+|\\+)'), "");
  }

  String get fileNameWithoutExt {
    var name = fileName;
    var extName = extension ?? "";
    //去除扩展名
    if (extName.isNotEmpty) {
      name = name.replaceLast(".$extName", "");
    }
    return name;
  }

  String? get extension {
    final name = fileName;
    if (!name.contains(".")) return null;
    final arr = name.split(".");
    return arr[arr.length - 1];
  }

  String buildDuplicateSeqName() {
    var name = fileNameWithoutExt;
    var extName = extension ?? "";
    const pattern = r"\(\d+\)$";
    final regExp = RegExp(pattern);
    final defaultSeqName = "$name(1)${extName.isEmpty ? "" : "."}$extName";
    if (name.matchRegExp(pattern)) {
      //如果已经包含序号判断是否为序号本身
      if (name.replaceAll(RegExp(pattern), "").isEmpty) {
        return defaultSeqName;
      }
      //提取序号并+1
      final start = regExp.firstMatch(name)!.start;
      var seq =
          name.substring(start).replaceAll(RegExp(r"[\\(\\)]"), "").toInt() + 1;
      name = name.replaceAll(regExp, "");
      return "$name($seq)${extName.isEmpty ? "" : "."}$extName";
    }
    return defaultSeqName;
  }

  Future<String?> get md5 async {
    if (!existsSync()) {
      return null;
    }
    return crypto.md5.convert(await readAsBytes()).toString();
  }

  bool get isMediaFile {
    // 获取文件扩展名（小写处理）
    var extName = extension?.toLowerCase();
    if (extName == null) {
      return false;
    }

    // 常见的图片、音频、视频文件扩展名
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'];
    const audioExtensions = ['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a'];
    const videoExtensions = ['mp4', 'avi', 'mkv', 'mov', 'wmv', 'flv'];

    // 判断文件是否属于以上三类之一
    return imageExtensions.contains(extName) ||
        audioExtensions.contains(extName) ||
        videoExtensions.contains(extName);
  }
}
