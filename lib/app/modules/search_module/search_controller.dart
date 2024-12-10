import 'dart:io';

import 'package:clipshare/app/data/models/clip_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class SearchController extends GetxController with WidgetsBindingObserver {
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();

  //region 属性
  static const tag = "SearchController";
  final TextEditingController textController = TextEditingController();
  final searchFocus = FocusNode();
  final list = List<ClipData>.empty(growable: true).obs;
  List<Device> allDevices = List.empty();
  List<String> allTagNames = List.empty();
  int? _minId;
  final loading = true.obs;

  //region 搜索相关
  bool get hasCondition =>
      selectedTags.isNotEmpty ||
      selectedDevIds.isNotEmpty ||
      searchStartDate.isNotEmpty ||
      searchEndDate.isNotEmpty ||
      searchOnlyNoSync;
  final selectedTags = <String>{}.obs;
  final selectedDevIds = <String>{}.obs;
  final _searchStartDate = "".obs;

  String get searchStartDate => _searchStartDate.value;

  set searchStartDate(value) => _searchStartDate.value = value;
  final _searchEndDate = "".obs;

  String get searchEndDate => _searchEndDate.value;

  set searchEndDate(value) => _searchEndDate.value = value;
  final _searchType = "全部".obs;

  String get searchType => _searchType.value;

  set searchType(value) => _searchType.value = value;
  final _searchOnlyNoSync = false.obs;

  bool get searchOnlyNoSync => _searchOnlyNoSync.value;

  set searchOnlyNoSync(value) => _searchOnlyNoSync.value = value;

  //endregion

  String get typeValue => HistoryContentType.typeMap.keys.contains(searchType)
      ? HistoryContentType.typeMap[searchType]!
      : "";

  final _screenWidth = Get.width.obs;

  set screenWidth(value) => _screenWidth.value = value;

  double get screenWidth => _screenWidth.value;

  bool get showLeftBar => screenWidth >= Constants.smallScreenWidth;

  //endregion

  //region 生命周期
  @override
  void onInit() {
    super.onInit();
    //监听生命周期
    WidgetsBinding.instance.addObserver(this);
    loadFromExternalParams(null, null);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    appConfig.disableMultiSelectionMode(true);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && Platform.isAndroid) {}
  }

//endregion

  //region 页面方法
  //根据外部参数刷新数据
  void loadFromExternalParams(String? devId, String? tagName) {
    //初始化搜索参数
    if (devId != null) {
      selectedDevIds.assignAll({devId});
      if (tagName == null) {
        selectedTags.clear();
      }
    }
    if (tagName != null) {
      selectedTags.assignAll({tagName});
      if (devId == null) {
        selectedDevIds.clear();
      }
    }
    //加载数据
    refreshData();
  }

  ///重新加载列表
  void refreshData() {
    _minId = null;
    loadSearchCondition();
    loadData(_minId).then((lst) {
      list.value = lst;
      loading.value = false;
    });
  }

  void sortList() {
    list.sort((a, b) => b.data.compareTo(a.data));
  }

  ///加载搜索条件
  Future<void> loadSearchCondition() async {
    //加载所有标签名
    await dbService.historyTagDao.getAllTagNames().then((lst) {
      allTagNames = lst;
    });
    //加载所有设备名
    await dbService.deviceDao.getAllDevices(appConfig.userId).then((lst) {
      var tmpLst = List<Device>.empty(growable: true);
      tmpLst.add(appConfig.device);
      tmpLst.addAll(lst);
      allDevices = tmpLst;
    });
  }

  ///加载数据
  Future<List<ClipData>> loadData(int? minId) {
    //加载搜索结果的前20条
    return dbService.historyDao
        .getHistoriesPageByWhere(
      appConfig.userId,
      minId ?? 0,
      textController.text,
      typeValue,
      selectedTags.toList(),
      selectedDevIds.toList(),
      searchStartDate,
      searchEndDate,
      searchOnlyNoSync,
    )
        .then((list) {
      if (PlatformExt.isDesktop) {
        searchFocus.requestFocus();
      }
      return ClipData.fromList(list);
    });
  }
//endregion
}
