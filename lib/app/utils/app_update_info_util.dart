import 'dart:convert';
import 'dart:io';

import 'package:clipshare/app/data/models/update_log.dart';
import 'package:clipshare/app/exceptions/fetch_update_logs_exception.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class AppUpdateInfoUtil {
  static Future<List<UpdateLog>> fetchUpdateLogs() async {
    final resp = await http.get(Uri.parse(Constants.appUpdateInfoUtl));
    if (resp.statusCode != 200) {
      throw FetchUpdateLogsException(resp.statusCode.toString());
    }
    final updateLogs = List<UpdateLog>.empty(growable: true);
    final body = jsonDecode(utf8.decode(resp.bodyBytes));
    final logs = body["logs"] as List<dynamic>;
    final system = Platform.operatingSystem;
    final appConfig = Get.find<ConfigService>();
    final currentVersion = appConfig.version;

    for (var log in logs) {
      log['url'] = body["downloads"][system.upperFirst()]["url"];
      final ul = UpdateLog.fromJson(log);
      if (ul.platform.toLowerCase() != system || ul.version <= currentVersion) {
        continue;
      }
      updateLogs.add(ul);
    }
    updateLogs.sort((a, b) => b.version - a.version);
    return updateLogs;
  }

  static Future<bool> showUpdateInfo() async {
    final logs = await fetchUpdateLogs();
    if (logs.isEmpty) {
      return false;
    }
    final latestVersionCode = logs.first.version.code;
    final appConfig = Get.find<ConfigService>();
    if (latestVersionCode == appConfig.ignoreUpdateVersion) {
      return false;
    }
    String content = "";
    for (var log in logs) {
      content += "🏷️${log.version}\n";
      content += "${log.desc}\n\n";
    }
    Global.showTipsDialog(
      context: Get.context!,
      title: "新版本",
      text: content,
      showCancel: true,
      showNeutral: true,
      neutralText: "跳过该次更新",
      cancelText: "取消",
      onNeutral: () {
        //写入数据库跳过更新的版本号
        appConfig.setIgnoreUpdateVersion(latestVersionCode);
      },
      okText: "下载更新",
      onOk: () {
        logs.first.downloadUrl.askOpenUrl();
      },
    );
    return true;
  }
}
