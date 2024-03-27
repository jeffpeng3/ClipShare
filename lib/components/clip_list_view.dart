import 'package:clipshare/components/clip_content_view.dart';
import 'package:clipshare/components/clip_data_card.dart';
import 'package:clipshare/components/clip_tag_row_view.dart';
import 'package:clipshare/components/rounded_chip.dart';
import 'package:clipshare/dao/history_dao.dart';
import 'package:clipshare/db/db_util.dart';
import 'package:clipshare/entity/clip_data.dart';
import 'package:clipshare/entity/tables/history.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/provider/device_info_provider.dart';
import 'package:clipshare/util/constants.dart';
import 'package:flutter/material.dart';
import 'package:highlighting/languages/all.dart';
import 'package:refena_flutter/refena_flutter.dart';

class ClipListView extends StatefulWidget {
  final List<ClipData> list;
  final void Function() onRefreshData;
  final bool enableRouteSearch;
  final BorderRadiusGeometry? detailBorderRadius;
  final Future<List<ClipData>> Function(int minId)? onLoadMoreData;

  const ClipListView({
    super.key,
    required this.list,
    required this.onRefreshData,
    this.onLoadMoreData,
    this.detailBorderRadius,
    this.enableRouteSearch = false,
  });

  @override
  State<ClipListView> createState() => ClipListViewState();
}

class ClipListViewState extends State<ClipListView>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final List<ClipData> _list = List.empty(growable: true);
  String? language;
  int? _minId;
  late HistoryDao _historyDao;
  static bool _loadNewData = false;
  var _showBackToTopButton = false;
  final String tag = "ClipListView";
  Key? _clipTagRowKey;
  bool _rightShowFullPage = false;
  ClipData? _showHistoryData;
  MenuController codeMenuController = MenuController();

  bool get showLeftBar =>
      MediaQuery.of(context).size.width >= Constants.showLeftBarWidth;

  bool get showHistoryRight =>
      MediaQuery.of(context).size.width >= Constants.showHistoryRightWidth;

  @override
  void initState() {
    super.initState();
    _loadNewData = false;
    _list.addAll(widget.list);
    _historyDao = DBUtil.inst.historyDao;
    if (_list.isNotEmpty) {
      _minId = _list.last.data.id;
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

  void updatePage(
    bool Function(History history) where,
    void Function(History history) cb,
  ) {
    for (var item in _list) {
      //查找符合条件的数据
      if (where(item.data)) {
        //更新数据
        cb(item.data);
        _sortList();
      }
    }
  }

  void _loadMoreData() {
    if (_loadNewData || _minId == null) {
      return;
    }
    _loadNewData = true;
    Future<List<ClipData>> f;
    if (widget.onLoadMoreData == null) {
      f = _historyDao
          .getHistoriesPage(App.userId, _minId!)
          .then((lst) => ClipData.fromList(lst));
    } else {
      f = widget.onLoadMoreData!.call(_minId!);
    }
    f.then((List<ClipData> list) {
      if (list.isNotEmpty) {
        _minId = list[list.length - 1].data.id;
        _list.addAll(list);
        _sortList();
      }
      Future.delayed(const Duration(milliseconds: 500), () {
        _loadNewData = false;
      });
    });
  }

  void _scrollListener() {
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

  void _sortList() {
    _list.sort((a, b) => b.data.compareTo(a.data));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: App.bgColor,
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
                    child: ListView.builder(
                      itemCount: _list.length,
                      controller: _scrollController,
                      itemBuilder: (context, i) {
                        return Container(
                          padding: const EdgeInsets.only(left: 2, right: 2),
                          constraints: const BoxConstraints(
                              maxHeight: 150, minHeight: 80),
                          child: ClipDataCard(
                            clip: _list[i],
                            routeToSearchOnClickChip: widget.enableRouteSearch,
                            onTap: () {
                              var data = _list[i];
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
                            },
                            onUpdate: () {
                              _sortList();
                            },
                            onRemove: (int id) {
                              _list.removeWhere(
                                (element) => element.data.id == id,
                              );
                              setState(() {});
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  _showBackToTopButton
                      ? Positioned(
                          bottom: 16,
                          right: 16,
                          child: FloatingActionButton(
                            onPressed: () {
                              Future.delayed(const Duration(milliseconds: 100),
                                  () {
                                _scrollController.animateTo(
                                  0,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                );
                                Future.delayed(
                                    const Duration(milliseconds: 600), () {
                                  var tmpList = _list.sublist(0, 20);
                                  _list.clear();
                                  _list.addAll(tmpList);
                                  setState(() {});
                                });
                              });
                            },
                            child: const Icon(Icons.arrow_upward), // 可以选择其他图标
                          ),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
          ),
          if (showHistoryRight && showLeftBar && _showHistoryData != null)
            Expanded(
              flex: _rightShowFullPage ? 1 : 0,
              child: SizedBox(
                width: _rightShowFullPage ? null : 350,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: widget.detailBorderRadius,
                    color: Colors.white,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Column(
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
                                        Icons.keyboard_double_arrow_right),
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
                                MenuAnchor(
                                  controller: codeMenuController,
                                  menuChildren: [
                                    for (var language in allLanguages.keys)
                                      SizedBox(
                                        width: 200,
                                        child: InkWell(
                                          child: Padding(
                                            padding: const EdgeInsets.all(7),
                                            child: Text(
                                              language,
                                              style: TextStyle(
                                                color: this.language == language
                                                    ? Colors.blue
                                                    : null,
                                              ),
                                            ),
                                          ),
                                          onTap: () {
                                            setState(() {
                                              codeMenuController.close();
                                              this.language =
                                                  this.language == language
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
                                            padding: const EdgeInsets.only(
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
                                              icon: const Icon(Icons.code,size: 20,),
                                            ),
                                          );
                                  },
                                ),
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
                              ViewModelBuilder(
                                provider: deviceInfoProvider,
                                builder: (context, vm) {
                                  return RoundedChip(
                                    avatar: const Icon(Icons.devices_rounded),
                                    backgroundColor: const Color(0x1a000000),
                                    label: Text(
                                      vm.getName(_showHistoryData!.data.devId),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  );
                                },
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
                              content: _showHistoryData!.data.content,
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
