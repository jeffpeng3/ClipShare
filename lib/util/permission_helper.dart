import 'dart:io';

import 'package:clipshare/main.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/log.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class PermissionHelper {
  PermissionHelper._private();

  static const tag = "PermissionHelper";

  ///测试存储权限
  static Future<bool> testAndroidStoragePerm([String? dirPath]) async {
    if (!Platform.isAndroid) return true;
    dirPath = dirPath ?? App.settings.fileStorePath;
    var isGranted = await Permission.storage.isGranted;
    if (isGranted && _testFileOperate(dirPath)) {
      return true;
    }
    if (App.osVersion >= 11 &&
        !dirPath.startsWith(Constants.androidDownloadPath)) {
      isGranted = await Permission.manageExternalStorage.isGranted;
      if (isGranted && _testFileOperate(dirPath)) {
        return true;
      }
    }
    return false;
  }

  ///请求Android存储权限
  static Future<void> reqAndroidStoragePerm([String? dirPath]) async {
    if (!Platform.isAndroid) return;
    dirPath = dirPath ?? App.settings.fileStorePath;
    if (!dirPath.startsWith(Constants.androidDownloadPath)) {
      var status = await Permission.manageExternalStorage.request();
      Log.info(tag, "request manageExternalStoragePermission: $status");
    }
    var status = await Permission.storage.request();
    Log.info(tag, "request storagePermission: $status");
  }

  ///测试文件操作
  static bool _testFileOperate(String dirPath) {
    //尝试创建文件夹和文件
    var dir = Directory(dirPath);
    if (dir.existsSync()) {
      try {
        var file = File("$dirPath/${const Uuid()}");
        file.createSync();
        file.deleteSync();
        return true;
      } catch (e) {
        return false;
      }
    } else {
      try {
        dir.createSync();
        return true;
      } catch (e) {
        return false;
      }
    }
  }

  ///Android短信读取权限
  static Future<bool> testAndroidReadSms() async {
    if (!Platform.isAndroid) return false;
    return await Permission.sms.isGranted;
  }

  ///Android短信读取权限请求
  static Future<void> reqAndroidReadSms() async {
    if (!Platform.isAndroid) return;
    var status = await Permission.sms.request();
    Log.info(tag, "request AndroidReadSms: $status");
  }
}
