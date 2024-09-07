import 'package:clipshare/app/data/chart/bar_chart_item.dart';
import 'package:clipshare/app/data/chart/pie_data_item.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/extension.dart';
import 'package:get/get.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class StatisticsController extends GetxController {
  final dbService = Get.find<DbService>();
  final appConfig = Get.find<ConfigService>();

  final startMonth = ''.obs;
  final endMonth = ''.obs;
  final historyTypeCntItems = RxList<BarChartItem>([]);
  final historyTagCntItems = RxList<PieDataItem>([]);
  final syncRatePieItems = RxList<PieDataItem>([]);
  final historyCntForDeviceItems = RxList<BarChartItem>([]);

  bool get isAllEmpty =>
      historyTypeCntItems.isEmpty &&
      historyTagCntItems.isEmpty &&
      syncRatePieItems.isEmpty &&
      historyCntForDeviceItems.isEmpty;

  //region 生命周期
  @override
  void onInit() {
    DateTime now = DateTime.now();
    DateTime firstDayOfMonth = DateTime(now.year, now.month);
    DateTime currentDate = DateTime(now.year, now.month);
    startMonth.value = firstDayOfMonth.format("yyyy-MM");
    endMonth.value = currentDate.format("yyyy-MM");
    super.onInit();
  }

  @override
  void onReady() {
    refreshData();
  }

  //endregion

  //region 页面方法

  void selectRangeMonth() async {
    var res = await showMonthRangePicker(context: Get.context!);
    if (res != null) {
      startMonth.value = res[0].format("yyyy-MM");
      endMonth.value = res[1].format("yyyy-MM");
    }
  }

  ///刷新页面
  Future<void> refreshData() async {
    await loadHistoryTypeCnt();
    await loadHistoryTagCnt();
    await loadHistoryCntForDevice();
  }

  ///不同类别的数量
  Future<void> loadHistoryTypeCnt() async {
    final typeCntList = await dbService.historyDao.getHistoryTypeCnt(
      appConfig.userId,
      startMonth.value,
      endMonth.value,
    );
    historyTypeCntItems.value = typeCntList
        .map((e) => BarChartItem(name: e.type, index: e.date, value: e.cnt))
        .toList();
  }

  ///各设备同步数量
  Future<void> loadHistoryCntForDevice() async {
    final res = await dbService.historyDao.getHistoryCntForDevice(
      appConfig.userId,
      startMonth.value,
      endMonth.value,
    );
    historyCntForDeviceItems.value = res
        .map((e) => BarChartItem(name: e.devName, value: e.cnt, index: e.month))
        .toList();
    String selfId = appConfig.device.guid;
    var sync = 0;
    var self = 0;
    for (var item in res) {
      if (item.devId == selfId) {
        self = item.cnt;
      } else {
        sync += item.cnt;
      }
    }
    if (res.isNotEmpty) {
      syncRatePieItems.value = [
        PieDataItem("本地", self),
        PieDataItem("同步", sync),
      ];
    } else {
      syncRatePieItems.value = [];
    }
  }

  ///各个标签的引用数量
  Future<void> loadHistoryTagCnt() async {
    final res = await dbService.historyTagDao.getHistoryTagCnt(
      appConfig.userId,
      startMonth.value,
      endMonth.value,
    );
    historyTagCntItems.value =
        res.map((e) => PieDataItem(e.tagName, e.cnt)).toList();
  }
//endregion
}
