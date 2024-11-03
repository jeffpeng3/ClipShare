import 'package:clipshare/app/modules/sync_file_module/sync_file_controller.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/syncing_file_progress_service.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class SyncFilePage extends GetView<SyncFileController> {
  static const logTag = "SyncFilePage";
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final syncingFileService = Get.find<SyncingFileProgressService>();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: controller.tabs.length,
      child: Scaffold(
        // backgroundColor: appConfig.bgColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: TabBar(
            tabs: [
              for (var tab in controller.tabs)
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
              onRefresh: controller.refreshHistoryFiles,
              child: Obx(
                () => Visibility(
                  visible: controller.recHistories.isEmpty,
                  replacement: Stack(
                    children: [
                      ListView.builder(
                        itemCount: controller.recHistories.length,
                        itemBuilder: (context, i) {
                          var data = controller.recHistories[i];
                          final id = data.historyId!;
                          var selected = controller.selected.containsKey(id);
                          return Column(
                            children: [
                              InkWell(
                                child: controller.recHistories[i].copyWith(
                                  selectMode: controller.selectMode,
                                  selected: selected,
                                ),
                                onLongPress: () {
                                  controller.selected[id] = data;
                                  controller.selectMode = true;
                                  appConfig.enableMultiSelectionMode(
                                    controller: controller,
                                    selectionTips: "多选删除",
                                  );
                                },
                                onTap: () {
                                  if (controller.selected.containsKey(id)) {
                                    controller.selected.remove(id);
                                  } else {
                                    controller.selected[id] = data;
                                  }
                                },
                              ),
                              Visibility(
                                visible:
                                    i != controller.recHistories.length - 1,
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
                              visible: controller.selectMode,
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
                                      "${controller.selected.length} / ${controller.recHistories.length}",
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
                              visible: controller.selectMode,
                              child: Tooltip(
                                message: "取消选择",
                                child: Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  child: FloatingActionButton(
                                    onPressed: () {
                                      controller.cancelSelectionMode();
                                      appConfig.disableMultiSelectionMode(true);
                                    },
                                    child: const Icon(Icons.close),
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: controller.selectMode &&
                                  controller.selected.isNotEmpty,
                              child: Tooltip(
                                message: "删除",
                                child: FloatingActionButton(
                                  onPressed: () {
                                    Global.showTipsDialog(
                                      context: context,
                                      text:
                                          "是否删除选中的 ${controller.selected.length} 项？\n发送记录的文件不会被删除",
                                      showCancel: true,
                                      showNeutral: true,
                                      neutralText: "连带文件删除",
                                      okText: "仅删除记录",
                                      autoDismiss: false,
                                      onOk: () async {
                                        await controller.deleteRecord(false);
                                        controller.selected.clear();
                                        controller.selectMode = false;
                                        appConfig
                                            .disableMultiSelectionMode(true);
                                      },
                                      onNeutral: () async {
                                        await controller.deleteRecord(true);
                                        controller.selected.clear();
                                        controller.selectMode = false;
                                        appConfig
                                            .disableMultiSelectionMode(true);
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
            ),
            Obx(
              () => Visibility(
                visible: controller.recList.isEmpty,
                replacement: ListView(
                  children: controller.recList,
                ),
                child: const EmptyContent(),
              ),
            ),
            Obx(
              () => Visibility(
                visible: controller.sendList.isEmpty,
                replacement: ListView(
                  children: controller.sendList,
                ),
                child: const EmptyContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
