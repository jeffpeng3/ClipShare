import 'package:clipshare/components/empty_content.dart';
import 'package:clipshare/components/sync_file_status.dart';
import 'package:clipshare/db/app_db.dart';
import 'package:clipshare/entity/syncing_file.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/provider/syncing_file_progress_providr.dart';
import 'package:clipshare/util/global.dart';
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
  bool _selectMode = false;
  Set<String> _selectedSet = {};
  var _count = 0;
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
                Visibility(
                  visible: recList.isEmpty,
                  replacement: ListView(
                    children: recList,
                  ),
                  child: const EmptyContent(),
                ),
                Visibility(
                  visible: sendList.isEmpty,
                  replacement: ListView(
                    children: sendList,
                  ),
                  child: const EmptyContent(),
                ),
                RefreshIndicator(
                  onRefresh: () {
                    _count++;
                    setState(() {});
                    return Future(() => null);
                  },
                  child: Visibility(
                    visible: historyList.isEmpty,
                    replacement: Stack(
                      children: [
                        ListView.builder(
                          itemCount: historyList.length,
                          itemBuilder: (context, i) {
                            var path = historyList[i].syncingFile.filePath;
                            var selected = _selectedSet.contains(path);
                            return Column(
                              children: [
                                InkWell(
                                  child: historyList[i].copyWith(
                                    selectMode: _selectMode,
                                    selected: selected,
                                  ),
                                  onLongPress: () {
                                    _selectedSet.add(path);
                                    _selectMode = true;
                                    setState(() {});
                                  },
                                  onTap: () {
                                    print(123);
                                    if (_selectedSet.contains(path)) {
                                      _selectedSet.remove(path);
                                    } else {
                                      _selectedSet.add(path);
                                    }
                                    setState(() {});
                                  },
                                ),
                                Visibility(
                                  visible: i != historyList.length - 1,
                                  child: const Divider(
                                    height: 0,
                                    indent: 10,
                                    endIndent: 10,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: Row(
                            children: [
                              Visibility(
                                visible: _selectMode,
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.lightBlue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  margin: const EdgeInsets.only(right: 10),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      child: Text(
                                        "${_selectedSet.length} / ${historyList.length}",
                                        style: const TextStyle(
                                          fontSize: 20,
                                          color: Colors.black45,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Visibility(
                                visible: _selectMode,
                                child: Tooltip(
                                  message: "取消选择",
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 10),
                                    child: FloatingActionButton(
                                      onPressed: () {
                                        _selectedSet.clear();
                                        _selectMode = false;
                                        setState(() {});
                                      },
                                      child: const Icon(Icons.close),
                                    ),
                                  ),
                                ),
                              ),
                              Visibility(
                                visible: _selectMode && _selectedSet.isNotEmpty,
                                child: Tooltip(
                                  message: "删除",
                                  child: FloatingActionButton(
                                    onPressed: () {
                                      Global.showTipsDialog(
                                        context: context,
                                        text:
                                            "是否删除选中的 ${_selectedSet.length} 项？",
                                        showCancel: true,
                                        neutralText: "连带文件删除",
                                        okText: "仅删除记录",
                                        onOk: () {
                                          _selectedSet.clear();
                                          _selectMode = false;
                                          setState(() {});
                                        },
                                        onNeutral: () {},
                                      );
                                    },
                                    child: const Icon(Icons.delete_forever),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    child: const EmptyContent(),
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
