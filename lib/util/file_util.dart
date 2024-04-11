import 'dart:io';

import 'package:open_filex/open_filex.dart';

class FileUtil {
  static int getDirectorySize(String directoryPath) {
    Directory directory = Directory(directoryPath);
    int totalSize = 0;
    if (!directory.existsSync()) return 0;
    directory.listSync(recursive: true).forEach((FileSystemEntity entity) {
      if (entity is File) {
        totalSize += entity.lengthSync();
      }
    });
    return totalSize;
  }

  // 递归删除目录下所有文件
  static void deleteDirectoryFiles(String directoryPath) {
    Directory directory = Directory(directoryPath);
    directory.listSync().forEach((FileSystemEntity entity) {
      if (entity is File) {
        entity.deleteSync(); // 删除文件
      } else if (entity is Directory) {
        deleteDirectoryFiles(entity.path); // 递归删除子目录下的文件
        entity.deleteSync(); // 删除子目录
      }
    });
  }
}
