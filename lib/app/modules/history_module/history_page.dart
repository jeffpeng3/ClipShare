import 'package:clipshare/app/modules/history_module/history_controller.dart';
import 'package:clipshare/app/widgets/clip_list_view.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class HistoryPage extends GetView<HistoryController> {
  @override
  Widget build(BuildContext context) {
    print("update historylist");
    return Obx(
      () => Visibility(
        visible: controller.loading,
        replacement: ClipListView(
          key: controller.key.value,
          list: controller.list,
          onRefreshData: controller.refreshData,
          enableRouteSearch: true,
          onUpdate: controller.sortList,
          onRemove: (id) {
            controller.list.removeWhere(
              (element) => element.data.id == id,
            );
            controller.updateLatestLocalClip();
            controller.debounceSetState();
          },
        ),
        child: const Loading(),
      ),
    );
  }
}
