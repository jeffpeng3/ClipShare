import 'package:clipshare/app/data/enums/translation_key.dart';
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
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart),
            const SizedBox(width: 10),
            Text(TranslationKey.statisticsPageAppBarText.tr),
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
                Text(TranslationKey.statisticsPageFilterRangeText.tr),
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
                  message: TranslationKey.refresh.tr,
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
                                title: TranslationKey.statisticsPageHistoryTypeCntTitle.tr,
                              ),
                            if (controller.syncRatePieItems.isNotEmpty)
                              PieChart(
                                data: controller.syncRatePieItems,
                                title: TranslationKey.statisticsPageSyncRatePie.tr,
                              ),
                            if (controller.historyCntForDeviceItems.isNotEmpty)
                              BarChart(
                                data: controller.historyCntForDeviceItems,
                                title: TranslationKey.statisticsPageHistoryCntForDevice.tr,
                              ),
                            if (controller.historyTagCntItems.isNotEmpty)
                              BarChart(
                                data: controller.historyTagCntItems,
                                title: TranslationKey.statisticsPageHistoryTagCnt.tr,
                              ),
                          ],
                        ),
                        child: EmptyContent(),
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
