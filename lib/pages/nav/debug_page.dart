import 'package:clipshare/main.dart';
import 'package:flutter/material.dart';

import 'package:clipshare/db/app_db.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
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
      ],
    );
  }
}
