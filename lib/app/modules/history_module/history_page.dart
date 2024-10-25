import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/modules/history_module/history_controller.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/widgets/clip_list_view.dart';
import 'package:clipshare/app/widgets/condition_widget.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class HistoryPage extends GetView<HistoryController> {
  final dbService = Get.find<DbService>();

  @override
  Widget build(BuildContext context) {
    //此处不可以用Visibility组件控制渲染，会导致RoundedClip组件背景色失效
    return Obx(
      () => ConditionWidget(
        condition: controller.loading,
        visible: const Loading(),
        invisible: ClipListView(
          list: controller.list,
          parentController: controller,
          onRefreshData: controller.refreshData,
          enableRouteSearch: true,
          onUpdate: () {
            controller.sortList();
            //通知子窗体
            controller.notifyCompactWindow();
          },
          onRemove: (id) {
            controller.removeById(id);
            //更新最新本地记录
            controller.updateLatestLocalClip();
          },
        ),
      ),
    );
  }
}
