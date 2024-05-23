import 'dart:io';

class FileUtil {
  FileUtil._private();
  ///递归获取文件夹大小
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

  /// 递归删除目录下所有文件
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

  /// 移动文件
  static void moveFile(String sourcePath, String destinationPath) {
    File sourceFile = File(sourcePath);
    File destFile = File(destinationPath);
    destFile.writeAsBytesSync(sourceFile.readAsBytesSync());
    sourceFile.deleteSync();
  }
}
