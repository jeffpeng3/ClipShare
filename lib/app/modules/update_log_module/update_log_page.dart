import 'package:clipshare/app/modules/update_log_module/update_log_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class UpdateLogPage extends GetView<UpdateLogController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('更新日志')),
      body: FutureBuilder(
        future: rootBundle.loadString("assets/md/updateLogs.md"),
        builder: (context, v) {
          return Markdown(
            data: v.data ?? "读取更新日志失败！",
            selectable: true,
            onSelectionChanged: (
              String? text,
              TextSelection selection,
              SelectionChangedCause? cause,
            ) {},
          );
        },
      ),
    );
  }
}
