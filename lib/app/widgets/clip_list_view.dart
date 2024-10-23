import 'dart:io';
import 'dart:math';

import 'package:clipboard_listener/clipboard_manager.dart';
import 'package:clipboard_listener/enums.dart';
import 'package:clipshare/app/data/repository/entity/clip_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/modules/history_module/history_controller.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/channels/clip_channel.dart';
import 'package:clipshare/app/services/channels/multi_window_channel.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/device_service.dart';
import 'package:clipshare/app/services/socket_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/widgets/clip_content_view.dart';
import 'package:clipshare/app/widgets/clip_data_card.dart';
import 'package:clipshare/app/widgets/clip_tag_row_view.dart';
import 'package:clipshare/app/widgets/rounded_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:highlighting/languages/all.dart';
import 'package:open_file_plus/open_file_plus.dart';

import 'empty_content.dart';

class ClipListView extends StatefulWidget {
  final RxList<ClipData> list;
  final void Function() onRefreshData;
  final bool enableRouteSearch;
  final BorderRadiusGeometry? detailBorderRadius;
  final Future<List<ClipData>> Function(int minId)? onLoadMoreData;
  final void Function() onUpdate;
  final void Function(int id) onRemove;
  final bool imageMasonryGridViewLayout;

  const ClipListView({
    super.key,
    required this.list,
    required this.onRefreshData,
    this.onLoadMoreData,
    this.detailBorderRadius,
    this.enableRouteSearch = false,
    required this.onUpdate,
    required this.onRemove,
    this.imageMasonryGridViewLayout = false,
  });

  @override
  State<ClipListView> createState() => ClipListViewState();
}

class ClipListViewState extends State<ClipListView>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final _scrollPhysics = const AlwaysScrollableScrollPhysics();
  String? language;
  int? _minId;
  final appConfig = Get.find<ConfigService>();
  final sktService = Get.find<SocketService>();
  final dbService = Get.find<DbService>();
  final devService = Get.find<DeviceService>();
  final androidChannelService = Get.find<AndroidChannelService>();
  final clipChannelService = Get.find<ClipChannelService>();
  final multiWindowChannelService = Get.find<MultiWindowChannelService>();
  static bool _loadNewData = false;
  var _showBackToTopButton = false;
  final String tag = "ClipListView";
  var _selectMode = false;
  final _selectedItems = <ClipData>{};
  Key? _clipTagRowKey;
  bool _rightShowFullPage = false;
  ClipData? _showHistoryData;
  MenuController codeMenuController = MenuController();

  bool get showLeftBar =>
      MediaQuery.of(context).size.width >= Constants.smallScreenWidth;

  bool get showHistoryRight =>
      MediaQuery.of(context).size.width >= Constants.showHistoryRightWidth;

  @override
  void initState() {
    super.initState();
    _loadNewData = false;
    if (widget.list.isNotEmpty) {
      _minId = widget.list.last.data.id;
    }
    //监听生命周期
    WidgetsBinding.instance.addObserver(this);
    // 监听滚动事件
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 释放资源
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  ///加载更多数据
  void _loadMoreData() {
    if (_loadNewData || _minId == null) {
      return;
    }
    _loadNewData = true;
    Future<List<ClipData>> f;
    if (widget.onLoadMoreData == null) {
      f = dbService.historyDao
          .getHistoriesPage(appConfig.userId, _minId!)
          .then((lst) => ClipData.fromList(lst));
    } else {
      f = widget.onLoadMoreData!.call(_minId!);
    }
    f.then((List<ClipData> list) {
      if (list.isNotEmpty) {
        _minId = list[list.length - 1].data.id;
        widget.list.addAll(list);
        removeDuplicates();
        _sortList();
      }
      Future.delayed(const Duration(milliseconds: 500), () {
        _loadNewData = false;
      });
    });
  }

  ///移除重复项
  void removeDuplicates() {
    Map<int, ClipData> map = {};
    for (var clip in widget.list) {
      map[clip.data.id] = clip;
    }
    widget.list.value = map.values.toList(growable: true);
  }

  ///滚动监听
  void _scrollListener() {
    if (_scrollController.offset == 0) {
      Future.delayed(const Duration(milliseconds: 100), () {
        var tmpList = widget.list.sublist(0, min(widget.list.length, 20));
        widget.list.value = tmpList;
        if (tmpList.isNotEmpty) {
          _minId = tmpList.last.data.id;
        }
        setState(() {});
      });
    }
    // 判断是否快要滑动到底部
    if (_scrollController.position.extentAfter <= 200 && !_loadNewData) {
      _loadMoreData();
    }
    if (_scrollController.offset >= 300) {
      if (!_showBackToTopButton) {
        setState(() {
          _showBackToTopButton = true;
        });
      }
    } else {
      if (_showBackToTopButton) {
        setState(() {
          _showBackToTopButton = false;
        });
      }
    }
  }

  ///排序 list
  void _sortList() {
    widget.list.sort((a, b) => b.data.compareTo(a.data));
    setState(() {});
  }

  ///删除项目
  Future<void> deleteItem(ClipData item, [bool deleteFile = false]) async {
    await dbService.historyDao.deleteByCascade(item.data.id);
    widget.onRemove(item.data.id);
    final historyController = Get.find<HistoryController>();
    //通知子窗体
    historyController.notifyCompactWindow();
    //添加删除记录
    var opRecord = OperationRecord.fromSimple(
      Module.history,
      OpMethod.delete,
      item.data.id,
    );
    //通知其他设备
    dbService.opRecordDao.addAndNotify(opRecord);
    if (!item.isImage) {
      return;
    }
    //如果是图片，删除并更新媒体库
    final path = item.data.content;
    var file = File(path);
    if (!file.existsSync()) return;
    file.deleteSync();
    if (Platform.isAndroid) {
      androidChannelService.notifyMediaScan(path);
    }
  }

  ///渲染列表项
  Widget renderItem(int i) {
    var item = widget.list[i];
    return ClipDataCard(
      clip: widget.list[i],
      imageMode: widget.imageMasonryGridViewLayout,
      routeToSearchOnClickChip: widget.enableRouteSearch,
      selectMode: _selectMode,
      selected: _selectedItems.contains(item),
      onTap: () {
        if (_selectMode) {
          if (_selectedItems.contains(item)) {
            _selectedItems.remove(item);
          } else {
            _selectedItems.add(item);
          }
          setState(() {});
        } else {
          var data = widget.list[i];
          if (data.data.id != _showHistoryData?.data.id) {
            _showHistoryData = data;
            _clipTagRowKey = UniqueKey();
            setState(() {});
          } else {
            setState(() {
              _showHistoryData = null;
              _rightShowFullPage = false;
            });
          }
        }
      },
      onLongPress: () {
        appConfig.isMultiSelectionMode.value = true;
        appConfig.multiSelectionText.value = "多选删除";
        _selectMode = true;
        _selectedItems.add(item);
        setState(() {});
      },
      onDoubleTap: () async {
        if (widget.list[i].isFile) {
          await OpenFile.open(widget.list[i].data.content);
          return;
        }
        appConfig.innerCopy = true;
        History history = widget.list[i].data;
        var type = ClipboardContentType.parse(history.type);
        final res = await clipboardManager.copy(type, history.content);
        if (res) {
          Global.showSnackBarSuc(context, "复制成功");
        } else {
          Global.showSnackBarErr(context, "复制失败");
        }
      },
      onUpdate: widget.onUpdate,
      onRemoveClicked: (ClipData item) {
        Global.showTipsDialog(
          context: context,
          text: "确定删除该记录？",
          title: "删除提示",
          showCancel: true,
          showNeutral: item.isFile || item.isImage,
          neutralText: "连带文件删除",
          onOk: () => deleteItem(item),
          onNeutral: () => deleteItem(item, true),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appConfig.bgColor,
      body: Row(
        children: [
          Expanded(
            flex: showHistoryRight && _rightShowFullPage ? 0 : 1,
            child: SizedBox(
              width: showHistoryRight && _rightShowFullPage ? 0 : null,
              child: Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () async {
                      return Future.delayed(
                        const Duration(milliseconds: 500),
                        widget.onRefreshData,
                      );
                    },
                    child: widget.list.isEmpty
                        ? Stack(
                            children: [
                              ListView(),
                              const EmptyContent(),
                            ],
                          )
                        : widget.imageMasonryGridViewLayout
                            ? LayoutBuilder(
                                builder: (ctx, constraints) {
                                  var maxWidth = 200.0;
                                  var count = max(
                                    2,
                                    constraints.maxWidth ~/ maxWidth,
                                  );
                                  return Obx(
                                    () => MasonryGridView.count(
                                      crossAxisCount: count,
                                      mainAxisSpacing: 4,
                                      shrinkWrap: true,
                                      crossAxisSpacing: 4,
                                      itemCount: widget.list.length,
                                      controller: _scrollController,
                                      physics: _scrollPhysics,
                                      itemBuilder: (context, index) {
                                        return renderItem(index);
                                      },
                                    ),
                                  );
                                },
                              )
                            : Obx(
                                () => ListView.builder(
                                  itemCount: widget.list.length,
                                  controller: _scrollController,
                                  physics: _scrollPhysics,
                                  itemBuilder: (context, i) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      constraints: const BoxConstraints(
                                        maxHeight: 150,
                                        minHeight: 80,
                                      ),
                                      child: renderItem(i),
                                    );
                                  },
                                ),
                              ),
                  ),
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  "${_selectedItems.length} / ${widget.list.length}",
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
                                  _selectedItems.clear();
                                  _selectMode = false;
                                  appConfig.isMultiSelectionMode.value = false;
                                  setState(() {});
                                },
                                heroTag: 'deselectHistory',
                                child: const Icon(Icons.close),
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: _selectMode && _selectedItems.isNotEmpty,
                          child: Tooltip(
                            message: "删除",
                            child: Container(
                              margin: _showBackToTopButton
                                  ? const EdgeInsets.only(right: 10)
                                  : null,
                              child: FloatingActionButton(
                                onPressed: () {
                                  void multiDelete(bool deleteFile) async {
                                    Get.back();
                                    Global.showLoadingDialog(
                                      context: context,
                                      loadingText: "删除中...",
                                    );
                                    for (var item in _selectedItems) {
                                      await deleteItem(item, deleteFile);
                                    }
                                    Get.back();
                                    Global.showSnackBarSuc(
                                      context,
                                      "删除完成",
                                    );
                                    _selectedItems.clear();
                                    _selectMode = false;
                                    appConfig.isMultiSelectionMode.value =
                                        false;
                                    setState(() {});
                                  }

                                  Global.showTipsDialog(
                                    context: context,
                                    text: "是否删除选中的 ${_selectedItems.length} 项？",
                                    showCancel: true,
                                    autoDismiss: false,
                                    showNeutral: true,
                                    neutralText: "连带文件删除",
                                    onCancel: () {
                                      Navigator.pop(context);
                                    },
                                    onNeutral: () => multiDelete(true),
                                    onOk: () => multiDelete(false),
                                  );
                                },
                                heroTag: 'deleteHistory',
                                child: const Icon(Icons.delete_forever),
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: _showBackToTopButton,
                          child: Tooltip(
                            message: "返回顶部",
                            child: FloatingActionButton(
                              onPressed: () {
                                Future.delayed(
                                    const Duration(milliseconds: 100), () {
                                  _scrollController.animateTo(
                                    0,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                });
                              },
                              heroTag: 'backToTop',
                              child: const Icon(Icons.arrow_upward), // 可以选择其他图标
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showHistoryRight && showLeftBar && _showHistoryData != null)
            Expanded(
              flex: _rightShowFullPage ? 1 : 0,
              child: SizedBox(
                width: _rightShowFullPage ? null : 400,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: widget.detailBorderRadius,
                    color: Colors.white,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ///标题
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Tooltip(
                                  message: "收起",
                                  child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _showHistoryData = null;
                                        _rightShowFullPage = false;
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.keyboard_double_arrow_right,
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(left: 5),
                                  child: Text(
                                    "剪贴板详情",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                _showHistoryData!.isText
                                    ? MenuAnchor(
                                        controller: codeMenuController,
                                        menuChildren: [
                                          for (var language
                                              in allLanguages.keys)
                                            SizedBox(
                                              width: 200,
                                              child: InkWell(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(7),
                                                  child: Text(
                                                    language,
                                                    style: TextStyle(
                                                      color: this.language ==
                                                              language
                                                          ? Colors.blue
                                                          : null,
                                                    ),
                                                  ),
                                                ),
                                                onTap: () {
                                                  setState(() {
                                                    codeMenuController.close();
                                                    this.language =
                                                        this.language ==
                                                                language
                                                            ? null
                                                            : language;
                                                  });
                                                },
                                              ),
                                            ),
                                        ],
                                        style: MenuStyle(
                                          maximumSize: MaterialStateProperty
                                              .resolveWith<Size?>(
                                            (Set<MaterialState> states) {
                                              return const Size(150, 200);
                                            },
                                          ),
                                        ),
                                        crossAxisUnconstrained: false,
                                        consumeOutsideTap: true,
                                        builder: (context, controller, child) {
                                          onPressed() {
                                            if (controller.isOpen) {
                                              controller.close();
                                            } else {
                                              controller.open();
                                            }
                                          }

                                          return language != null
                                              ? RoundedChip(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    left: 2,
                                                    right: 2,
                                                  ),
                                                  label: Text(
                                                    language!,
                                                    style: const TextStyle(
                                                      color: Colors.blue,
                                                    ),
                                                  ),
                                                  onPressed: onPressed,
                                                )
                                              : Tooltip(
                                                  message: "源代码模式",
                                                  child: IconButton(
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    onPressed: onPressed,
                                                    icon: const Icon(
                                                      Icons.code,
                                                      size: 20,
                                                    ),
                                                  ),
                                                );
                                        },
                                      )
                                    : const SizedBox.shrink(),
                              ],
                            ),
                            Tooltip(
                              message: "关闭",
                              child: IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  setState(() {
                                    setState(() {
                                      _rightShowFullPage = false;
                                      _showHistoryData = null;
                                    });
                                  });
                                },
                                icon: const Icon(Icons.close),
                              ),
                            ),
                          ],
                        ),

                        ///标签栏
                        Padding(
                          padding: const EdgeInsets.only(top: 5, bottom: 5),
                          child: Row(
                            children: [
                              ///来源设备
                              Obx(
                                () => RoundedChip(
                                  avatar: const Icon(Icons.devices_rounded),
                                  backgroundColor: const Color(0x1a000000),
                                  label: Text(
                                    devService
                                        .getName(_showHistoryData!.data.devId),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 5,
                              ),

                              ///持有标签
                              Expanded(
                                child: ClipTagRowView(
                                  key: _clipTagRowKey,
                                  hisId: _showHistoryData!.data.id,
                                  clipBgColor: const Color(0x1a000000),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(
                          height: 0.1,
                          color: Color(0xE1E1E0FF),
                        ),

                        ///剪贴板内容
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5, bottom: 5),
                            child: ClipContentView(
                              key: _clipTagRowKey,
                              clipData: _showHistoryData!,
                              language: language,
                            ),
                          ),
                        ),
                        const Divider(
                          height: 0.1,
                          color: Color(0xE1E1E0FF),
                        ),

                        ///底部操作栏
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Tooltip(
                                message: _rightShowFullPage ? "收起" : "展开",
                                child: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _rightShowFullPage = !_rightShowFullPage;
                                    });
                                  },
                                  icon: Icon(
                                    _rightShowFullPage
                                        ? Icons.keyboard_double_arrow_right
                                        : Icons.keyboard_double_arrow_left,
                                  ),
                                ),
                              ),
                              Text(_showHistoryData!.timeStr),
                              Text(_showHistoryData!.sizeText),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}
