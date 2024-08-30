import 'dart:io';

import 'package:clipshare/app/data/repository/entity/syncing_file.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/syncing_file_progress_service.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:clipshare/app/widgets/sync_file_status.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

class _SyncingFilePageState extends State<SyncingFilePage> {
  bool _selectMode = false;

  final Map<int, SyncFileStatus> _selected = {};
  static const tag = "SyncingFilePage";
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final syncingFileService = Get.find<SyncingFileProgressService>();
  var _count = 0;
  List<_SyncingFilePageTab> tabs = [
    _SyncingFilePageTab(
      name: "历史",
      icon: const Icon(
        Icons.history,
        size: 18,
      ),
    ),
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
  ];

  Future refreshHistoryFiles() {
    _count++;
    setState(() {});
    return Future(() => null);
  }

  List<Column> getSendList() {
    final syncingList = syncingFileService.getSyncingFiles();
    return syncingList
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
  }

  List<Column> getRecList() {
    final syncingList = syncingFileService.getSyncingFiles();
    return syncingList
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
  }

  void deleteRecord(bool withFile) {
    Navigator.pop(context);
    Global.showLoadingDialog(
      context: context,
      loadingText: "删除中...",
    );
    dbService.historyDao
        .deleteByIds(
      _selected.keys.toList(),
      appConfig.userId,
    )
        .then((cnt) {
      if (cnt != null && cnt > 0) {
        bool hasError = false;
        if (withFile) {
          //删除本地文件
          final files = _selected.values;
          for (var syncFile in files) {
            if (syncFile.syncingFile.isSender) continue;
            final filePath = syncFile.syncingFile.filePath;
            try {
              var file = File(filePath);
              if (file.existsSync()) {
                file.deleteSync();
              }
            } catch (e, stack) {
              Log.error(
                tag,
                "删除文件 $filePath 失败: $e $stack",
              );
              hasError = true;
            }
          }
        }
        refreshHistoryFiles();
        Navigator.pop(context);
        if (hasError) {
          Global.showSnackBarWarn(
            context,
            "部分删除失败",
          );
        } else {
          Global.showSnackBarSuc(
            context,
            "删除成功",
          );
        }
      } else {
        Global.showSnackBarErr(
          context,
          "删除失败",
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: dbService.historyDao.getFiles(appConfig.userId),
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
            backgroundColor: appConfig.bgColor,
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
                RefreshIndicator(
                  onRefresh: refreshHistoryFiles,
                  child: Visibility(
                    visible: historyList.isEmpty,
                    replacement: Stack(
                      children: [
                        ListView.builder(
                          itemCount: historyList.length,
                          itemBuilder: (context, i) {
                            var data = historyList[i];
                            final id = data.historyId!;
                            var selected = _selected.containsKey(id);
                            return Column(
                              children: [
                                InkWell(
                                  child: historyList[i].copyWith(
                                    selectMode: _selectMode,
                                    selected: selected,
                                  ),
                                  onLongPress: () {
                                    _selected[id] = data;
                                    _selectMode = true;
                                    appConfig.isMultiSelectionMode.value = true;
                                    appConfig.multiSelectionText.value = "多选删除";
                                    setState(() {});
                                  },
                                  onTap: () {
                                    if (_selected.containsKey(id)) {
                                      _selected.remove(id);
                                    } else {
                                      _selected[id] = data;
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
                        //多选删除
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
                                        horizontal: 10,
                                      ),
                                      child: Text(
                                        "${_selected.length} / ${historyList.length}",
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
                                        _selected.clear();
                                        _selectMode = false;
                                        appConfig.isMultiSelectionMode.value =
                                            false;
                                        setState(() {});
                                      },
                                      child: const Icon(Icons.close),
                                    ),
                                  ),
                                ),
                              ),
                              Visibility(
                                visible: _selectMode && _selected.isNotEmpty,
                                child: Tooltip(
                                  message: "删除",
                                  child: FloatingActionButton(
                                    onPressed: () {
                                      Global.showTipsDialog(
                                        context: context,
                                        text:
                                            "是否删除选中的 ${_selected.length} 项？\n 发送记录的文件不会被删除",
                                        showCancel: true,
                                        showNeutral: true,
                                        neutralText: "连带文件删除",
                                        okText: "仅删除记录",
                                        autoDismiss: false,
                                        onOk: () {
                                          deleteRecord(false);
                                          // _selectedPathSet.clear();
                                          _selected.clear();
                                          _selectMode = false;
                                          appConfig.isMultiSelectionMode.value =
                                              true;
                                          setState(() {});
                                        },
                                        onNeutral: () {
                                          deleteRecord(true);
                                          // _selectedPathSet.clear();
                                          _selected.clear();
                                          _selectMode = false;
                                          appConfig.isMultiSelectionMode.value =
                                              true;
                                          setState(() {});
                                        },
                                        onCancel: () {
                                          Get.back();
                                        },
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
                    child: Stack(
                      children: [const EmptyContent(), ListView()],
                    ),
                  ),
                ),
                Obx(
                  () => Visibility(
                    visible: getRecList().isEmpty,
                    replacement: ListView(
                      children: getRecList(),
                    ),
                    child: const EmptyContent(),
                  ),
                ),
                Obx(
                  () => Visibility(
                    visible: getSendList().isEmpty,
                    replacement: ListView(
                      children: getSendList(),
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
