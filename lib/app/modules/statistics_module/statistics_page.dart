import 'package:clipshare/app/modules/statistics_module/statistics_controller.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:clipshare/app/widgets/rounded_chip.dart';
import 'package:clipshare/app/widgets/statistics/bar_chart.dart';
import 'package:clipshare/app/widgets/statistics/pie_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class StatisticsPage extends GetView<StatisticsController> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth <= Constants.smallScreenWidth;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart),
            SizedBox(width: 10),
            Text("统计分析"),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshData,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                const Text("统计范围"),
                const SizedBox(width: 10),
                RoundedChip(
                  onPressed: controller.selectRangeMonth,
                  label: Obx(() => Text(controller.startMonth.value)),
                  avatar: const Icon(Icons.date_range_outlined),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 10, left: 10),
                  child: const Text("-"),
                ),
                RoundedChip(
                  onPressed: controller.selectRangeMonth,
                  label: Obx(() => Text(controller.endMonth.value)),
                  avatar: const Icon(Icons.date_range_outlined),
                ),
                Tooltip(
                  message: '刷新',
                  child: IconButton(
                    onPressed: () {
                      controller.refreshData();
                    },
                    icon: const Icon(Icons.refresh),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: Container()),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: screenWidth > Constants.smallScreenWidth
                          ? Constants.smallScreenWidth
                          : screenWidth,
                    ),
                    child: Obx(
                      () => Visibility(
                        visible: controller.isAllEmpty,
                        replacement: GridView.count(
                          crossAxisCount: isSmallScreen ? 1 : 2,
                          children: [
                            if (controller.historyTypeCntItems.isNotEmpty)
                              BarChart(
                                data: controller.historyTypeCntItems,
                                title: '各类别记录数量',
                              ),
                            if (controller.syncRatePieItems.isNotEmpty)
                              PieChart(
                                data: controller.syncRatePieItems,
                                title: '同步比例',
                              ),
                            if (controller.historyCntForDeviceItems.isNotEmpty)
                              BarChart(
                                data: controller.historyCntForDeviceItems,
                                title: '各设备记录数量',
                              ),
                            if (controller.historyTagCntItems.isNotEmpty)
                              BarChart(
                                data: controller.historyTagCntItems,
                                title: '各标签记录数量',
                              ),
                          ],
                        ),
                        child: const EmptyContent(),
                      ),
                    ),
                  ),
                  Expanded(child: Container()),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
