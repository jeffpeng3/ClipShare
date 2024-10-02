import 'dart:io';

import 'package:clipshare/app/data/repository/entity/clip_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class SearchController extends GetxController with WidgetsBindingObserver {
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();

  //region 属性
  String? devId;
  String? tagName;
  static const tag = "SearchController";
  final TextEditingController textController = TextEditingController();
  final searchFocus = FocusNode();
  final list = List<ClipData>.empty(growable: true).obs;
  List<Device> allDevices = List.empty();
  List<String> allTagNames = List.empty();
  int? _minId;
  static bool updating = false;
  final loading = true.obs;

  ///搜索相关
  var hasCondition = false;
  final Set<String> selectedTags = {};
  final Set<String> selectedDevIds = {};
  var searchStartDate = "";
  var searchEndDate = "";
  var searchType = "全部";
  var searchOnlyNoSync = false;

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
    //初始化搜索参数
    if (devId != null) {
      selectedDevIds.add(devId!);
    }
    if (tagName != null) {
      selectedTags.add(tagName!);
    }
    updating = false;
    //加载数据
    refreshData();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && Platform.isAndroid) {
      debounceSetState();
    }
  }

//endregion

  //region 页面方法
  //防抖更新
  void debounceSetState() {
    if (updating) {
      return;
    }
    updating = true;
    Future.delayed(const Duration(milliseconds: 500)).then((value) {
      updating = false;
      update();
    });
  }

  ///重新加载列表
  void refreshData() {
    list.clear();
    _minId = null;
    loadSearchCondition();
    loadData(_minId).then((lst) {
      list.value = lst;
      loading.value = false;
      debounceSetState();
    });
  }

  void sortList() {
    list.sort((a, b) => b.data.compareTo(a.data));
    debounceSetState();
  }

  ///加载搜索条件
  Future<void> loadSearchCondition() async {
    //加载所有标签名
    await dbService.historyTagDao.getAllTagNames().then((lst) {
      allTagNames = lst;
      debounceSetState();
    });
    //加载所有设备名
    await dbService.deviceDao.getAllDevices(appConfig.userId).then((lst) {
      var tmpLst = List<Device>.empty(growable: true);
      tmpLst.add(appConfig.device);
      tmpLst.addAll(lst);
      allDevices = tmpLst;
      debounceSetState();
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
      if (PlatformExt.isPC) {
        searchFocus.requestFocus();
      }
      return ClipData.fromList(list);
    });
  }
//endregion
}
