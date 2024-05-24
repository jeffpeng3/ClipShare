import 'dart:convert';
import 'dart:io';

import 'package:clipshare/channels/common_channel.dart';
import 'package:clipshare/components/device_card_simple.dart';
import 'package:clipshare/db/app_db.dart';
import 'package:clipshare/entity/tables/device.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/util/global.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  final ScrollController _controller = ScrollController();
  double visibleCharacterCount = 0;
  bool showBorder=false;
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
            AppDb.inst.historyDao.removeAllLocalHistories();
          },
          child: const Text("删除所有本地历史"),
        ),
        Container(
          height: 10,
        ),
        ElevatedButton(
          onPressed: () {
            AppDb.inst.deviceDao.removeAll(App.userId);
          },
          child: const Text("删除所有设备"),
        ),
        Container(
          height: 10,
        ),
        ElevatedButton(
          onPressed: () {
            AppDb.inst.historyTagDao.removeAll();
          },
          child: const Text("删除所有标签"),
        ),
        Container(
          height: 10,
        ),
        ElevatedButton(
          onPressed: () {
            AppDb.inst.opRecordDao.removeAll(App.userId);
            AppDb.inst.opSyncDao.removeAll(App.userId);
          },
          child: const Text("删除所有操作和同步记录"),
        ),
        Container(
          height: 10,
        ),
        ElevatedButton(
          onPressed: () {
            AppDb.inst.opSyncDao.resetSyncStatus(App.device.guid);
            AppDb.inst.opSyncDao.removeAll(App.userId);
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
            Global.notify("测试通知");
          },
          child: const Text("测试通知"),
        ),
        Container(height: 10,),
        DeviceCardSimple(dev: Device(guid: '1111', devName: 'Test', uid: 0, type: 'Android'), onTap: (){
          showBorder=!showBorder;
          setState(() {

          });
        },showBorder: showBorder,),
      ],
    );
  }
}
