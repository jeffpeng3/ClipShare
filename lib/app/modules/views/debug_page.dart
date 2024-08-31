import 'dart:convert';
import 'dart:io';

import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/listeners/clipboard_listener.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/device_card_simple.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  final ScrollController _controller = ScrollController();
  double visibleCharacterCount = 0;
  bool showBorder = false;
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      // mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () {
            dbService.historyDao.removeAllLocalHistories();
          },
          child: const Text("删除所有本地历史"),
        ),
        Container(
          height: 10,
        ),
        ElevatedButton(
          onPressed: () {
            dbService.deviceDao.removeAll(appConfig.userId);
          },
          child: const Text("删除所有设备"),
        ),
        Container(
          height: 10,
        ),
        ElevatedButton(
          onPressed: () {
            dbService.historyTagDao.removeAll();
          },
          child: const Text("删除所有标签"),
        ),
        Container(
          height: 10,
        ),
        ElevatedButton(
          onPressed: () {
            dbService.opRecordDao.removeAll(appConfig.userId);
            dbService.opSyncDao.removeAll(appConfig.userId);
          },
          child: const Text("删除所有操作和同步记录"),
        ),
        Container(
          height: 10,
        ),
        ElevatedButton(
          onPressed: () {
            dbService.opSyncDao.resetSyncStatus(appConfig.device.guid);
            dbService.opSyncDao.removeAll(appConfig.userId);
          },
          child: const Text("重置所有记录为未同步"),
        ),
        Container(
          height: 10,
        ),
        Visibility(
          visible: Platform.isWindows,
          child: ElevatedButton(
            onPressed: () async {
              final window = await DesktopMultiWindow.createWindow(
                jsonEncode({
                  'args1': 'Sub window',
                  'args2': 100,
                  'args3': true,
                  'business': 'business_test',
                }),
              );
              window
                ..setFrame(const Offset(0, 0) & const Size(400, 720))
                ..center()
                ..setTitle('Another window')
                ..show();
            },
            child: const Text("新窗口"),
          ),
        ),
        Container(
          height: 10,
        ),
        ElevatedButton(
          onPressed: () async {
            for (var i in List.generate(200, (index) => index)) {
              ClipboardListener.inst.onChanged(ContentType.text, i.toString());
            }
          },
          child: const Text("大量数据同步"),
        ),
        Container(
          height: 10,
        ),
      ],
    );
  }
}
