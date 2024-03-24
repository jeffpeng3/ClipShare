import 'package:flutter/material.dart';

import '../../db/db_util.dart';
import '../../main.dart';

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
            DBUtil.inst.historyDao.removeAllLocalHistories();
          },
          child: const Text("删除所有本地历史"),
        ),
        Container(
          height: 10,
        ),
        ElevatedButton(
          onPressed: () {
            DBUtil.inst.deviceDao.removeAll(App.userId);
          },
          child: const Text("删除所有设备"),
        ),
        Container(
          height: 10,
        ),
        ElevatedButton(
          onPressed: () {
            DBUtil.inst.historyTagDao.removeAll();
          },
          child: const Text("删除所有标签"),
        ),
        Container(
          height: 10,
        ),
        ElevatedButton(
          onPressed: () {
            DBUtil.inst.opRecordDao.removeAll(App.userId);
            DBUtil.inst.opSyncDao.removeAll(App.userId);
          },
          child: const Text("删除所有操作和同步记录"),
        ),
        Container(
          height: 10,
        ),
        ElevatedButton(
          onPressed: () {
            DBUtil.inst.opSyncDao.resetSyncStatus(App.device.guid);
            DBUtil.inst.opSyncDao.removeAll(App.userId);
          },
          child: const Text("重置所有记录为未同步"),
        ),
      ],
    );
  }
}
