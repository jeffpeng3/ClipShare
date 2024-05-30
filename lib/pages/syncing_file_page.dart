import 'package:clipshare/components/empty_content.dart';
import 'package:clipshare/components/sync_file_status.dart';
import 'package:clipshare/db/app_db.dart';
import 'package:clipshare/entity/syncing_file.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/provider/syncing_file_progress_providr.dart';
import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';

class SyncingFilePage extends StatefulWidget {
  const SyncingFilePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SyncingFilePageState();
  }
}

class _SyncingFilePageTab {
  final String name;
  final Icon icon;

  _SyncingFilePageTab({required this.name, required this.icon});
}

class _SyncingFilePageState extends State<SyncingFilePage> with Refena {
  var factor = 1;
  var count = 0;
  List<_SyncingFilePageTab> tabs = [
    _SyncingFilePageTab(
      name: "接收",
      icon: const Icon(
        Icons.file_download,
        size: 18,
      ),
    ),
    _SyncingFilePageTab(
      name: "发送",
      icon: const Icon(
        Icons.upload,
        size: 18,
      ),
    ),
    _SyncingFilePageTab(
      name: "历史",
      icon: const Icon(
        Icons.history,
        size: 18,
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final syncingList =
        context.ref.watch(syncingFileProgressProvider).getSyncingFiles();
    var sendList = syncingList
        .where((file) => file.isSender && file.state != SyncingFileState.done)
        .map(
          (e) => Column(
            children: [
              SyncFileStatus(
                syncingFile: e,
                factor: e.savedBytes / e.totalSize,
              ),
              const Divider(
                height: 0,
                indent: 10,
                endIndent: 10,
              ),
            ],
          ),
        )
        .toList();
    var recList = syncingList
        .where((file) => !file.isSender && file.state != SyncingFileState.done)
        .map(
          (e) => Column(
            children: [
              SyncFileStatus(
                syncingFile: e,
                factor: e.savedBytes / e.totalSize,
              ),
              const Divider(
                height: 0,
                indent: 10,
                endIndent: 10,
              ),
            ],
          ),
        )
        .toList();
    return FutureBuilder(
      future: AppDb.inst.historyDao.getFiles(App.userId),
      builder: (context, snapshot) {
        var historyList = List<SyncFileStatus>.empty(growable: true);
        var lst = snapshot.data;
        if (lst != null) {
          for (var history in lst) {
            historyList.add(SyncFileStatus.fromHistory(context, history));
          }
        }
        return DefaultTabController(
          length: tabs.length,
          child: Scaffold(
            backgroundColor: App.bgColor,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: TabBar(
                tabs: [
                  for (var tab in tabs)
                    Tab(
                      child: IntrinsicWidth(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(tab.name),
                            const SizedBox(
                              width: 5,
                            ),
                            tab.icon,
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                recList.isEmpty
                    ? const EmptyContent()
                    : ListView(
                        children: recList,
                      ),
                sendList.isEmpty
                    ? const EmptyContent()
                    : ListView(
                        children: sendList,
                      ),
                RefreshIndicator(
                  onRefresh: () {
                    count++;
                    setState(() {});
                    return Future(() => null);
                  },
                  child: historyList.isEmpty
                      ? const EmptyContent()
                      : ListView.builder(
                          itemCount: historyList.length,
                          itemBuilder: (context, i) {
                            return Column(
                              children: [
                                historyList[i],
                                const Divider(
                                  height: 0,
                                  indent: 10,
                                  endIndent: 10,
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
