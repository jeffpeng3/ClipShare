import 'dart:convert';
import 'dart:io';

import 'package:clipshare/components/large_text.dart';
import 'package:clipshare/db/app_db.dart';
import 'package:clipshare/main.dart';
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
  var text =
      "11111112354684654654654655\n6416545613465132486513246df\nsajfkladsjfawiohnkljfsa\n  f4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as111111123546846546546546556416545613465132486513246dfsajfkladsjfawiohnkljfsadf4sad687g6sdg4asdgvf7sa68d4gbsad65g4va65swdeg48a6ewrg746a4sg64as8d4g86asd4g5asdg4as";

  @override
  void initState() {
    super.initState();
    List<int>.generate(10, (index) => index + 1).forEach((element) {
      text += text;
    });
    print("textlength " + text.length.toString());
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
        SizedBox(
          height: 200,
          child: LargeText(
            text: text,
            bottomThreshold: 0.3,
            blockSize: 1000,
            onThresholdChanged: (String text) => Text(text),
          ),
        ),
      ],
    );
  }
}
