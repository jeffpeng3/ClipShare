import 'package:clipshare/app/modules/history_module/history_controller.dart';
import 'package:clipshare/app/widgets/clip_list_view.dart';
import 'package:clipshare/app/widgets/condition_widget.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class HistoryPage extends GetView<HistoryController> {
  @override
  Widget build(BuildContext context) {
    //此处不可以用Visibility组件控制渲染，会导致RoundedClip组件背景色失效
    return Obx(
      () => ConditionWidget(
        condition: controller.loading,
        visible: const Loading(),
        invisible: ClipListView(
          list: controller.list,
          onRefreshData: controller.refreshData,
          enableRouteSearch: true,
          onUpdate: controller.sortList,
          onRemove: (id) {
            controller.removeById(id);
            controller.updateLatestLocalClip();
          },
        ),
      ),
    );
  }
}
