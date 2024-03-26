import 'dart:math';

import 'package:clipshare/components/rounded_chip.dart';
import 'package:clipshare/db/db_util.dart';
import 'package:clipshare/entity/clip_data.dart';
import 'package:clipshare/entity/tables/device.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/util/extension.dart';
import 'package:flutter/material.dart';

import '../components/clip_data_card.dart';

class SearchPage extends StatefulWidget {
  final String? devId;
  final String? tagName;

  const SearchPage({
    super.key,
    this.devId,
    this.tagName,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with WidgetsBindingObserver {
  static const tag = "SearchPage";

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ClipData> _list = List.empty(growable: true);
  List<Device> _allDevices = List.empty();
  List<String> _allTagNames = List.empty();
  int? _minId;
  final _searchFocus = FocusNode();
  var _showBackToTopButton = false;

  ///搜索相关
  final Set<String> _selectedTags = {};
  final Set<String> _selectedDevIds = {};
  var searchStartDate = "";
  var searchEndDate = "";
  var searchType = "全部";
  var typeMap = {
    "全部": "",
    "文本": "Text",
    "图片": "Img",
    "富文本": "RichText",
    "文件": "File",
  };

  String get typeValue =>
      typeMap.keys.contains(searchType) ? typeMap[searchType]! : "";

  @override
  void initState() {
    super.initState();
    //监听生命周期
    WidgetsBinding.instance.addObserver(this);
    // 监听滚动事件
    _scrollController.addListener(_scrollListener);
    //初始化搜索参数
    if (widget.devId != null) {
      _selectedDevIds.add(widget.devId!);
    }
    if (widget.tagName != null) {
      _selectedTags.add(widget.tagName!);
    }
    //加载数据
    refreshData();
  }

  void _scrollListener() {
    // 判断是否快要滑动到底部
    if (_scrollController.position.extentAfter <= 200) {
      // 滑动到底部的处理逻辑
      if (_minId == null) return;
      _loadData();
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

  ///重新加载列表
  void refreshData() {
    _list.clear();
    _minId = null;
    //加载所有标签名
    DBUtil.inst.historyTagDao.getAllTagNames().then((lst) {
      setState(() {
        _allTagNames = lst;
      });
    });
    //加载所有设备名
    DBUtil.inst.deviceDao.getAllDevices(App.userId).then((lst) {
      var tmpLst = List<Device>.empty(growable: true);
      tmpLst.add(App.device);
      tmpLst.addAll(lst);
      setState(() {
        _allDevices = tmpLst;
      });
    });
    _loadData();
  }

  void _loadData() {
    //加载搜索结果的前20条
    DBUtil.inst.historyDao
        .getHistoriesPageByWhere(
      App.userId,
      _minId ?? 0,
      _textController.text,
      typeValue,
      _selectedTags.toList(),
      _selectedDevIds.toList(),
      searchStartDate,
      searchEndDate,
    )
        .then((list) {
      _list.addAll(ClipData.fromList(list));
      for (int i = 0; i < _list.length; i++) {
        ClipData item = _list[i];
        if (_minId == null) {
          _minId = item.data.id;
        } else {
          _minId = min(_minId!, item.data.id);
        }
      }
      setState(() {});
      if (PlatformExt.isPC) {
        _searchFocus.requestFocus();
      }
    });
  }

  ///加载扩展搜索底部弹窗
  void _showExtendSearchDialog() {
    showModalBottomSheet(
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      context: context,
      elevation: 100,
      builder: (context) {
        var start = searchStartDate == "" ? "开始日期" : searchStartDate;
        var end = searchEndDate == "" ? "结束日期" : searchEndDate;
        var now = DateTime.now();
        var nowDayStr = now.toString().substring(0, 10);
        var tags = Set<String>.from(_selectedTags);
        var devs = Set<String>.from(_selectedDevIds);
        onDateRangeClick(state) async {
          //显示时间选择器
          DateTimeRange range = await showDateRangePicker(
                //语言环境
                locale: const Locale("zh", "CH"),
                context: context,
                //开始时间
                firstDate: DateTime(1970, 1),
                //结束时间
                lastDate: DateTime(2100, 12),
                cancelText: "取消",
                confirmText: "确定",
                useRootNavigator: true,
                //初始的时间范围选择
                initialDateRange: DateTimeRange(
                  start: DateTime.now(),
                  end: DateTime.now(),
                ),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(App.context),
                    child: child!,
                  );
                },
              ) ??
              DateTimeRange(
                start: now,
                end: now,
              );
          start = range.start.toString().substring(0, 10);
          end = range.end.toString().substring(0, 10);
          state(() {});
        }

        return StatefulBuilder(
          builder: (context, setInnerState) {
            return Container(
              padding: const EdgeInsets.all(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView(
                  children: [
                    //筛选日期 label
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "筛选日期",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              searchStartDate =
                                  start.contains("日期") ? "" : start;
                              searchEndDate = end.contains("日期") ? "" : end;
                              _selectedTags.clear();
                              _selectedTags.addAll(tags);
                              _selectedDevIds.clear();
                              _selectedDevIds.addAll(devs);
                              refreshData();
                            },
                            child: const Text("确定"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Row(
                      children: [
                        RoundedChip(
                          onPressed: () => onDateRangeClick(setInnerState),
                          label: Text(
                            start,
                            style: TextStyle(
                              color: searchStartDate == "" && start == "开始日期"
                                  ? Colors.grey
                                  : null,
                            ),
                          ),
                          avatar: const Icon(Icons.date_range_outlined),
                          deleteIcon: const Icon(
                            Icons.location_on,
                            size: 17,
                            color: Colors.blue,
                          ),
                          deleteButtonTooltipMessage: "定位到今天",
                          onDeleted: start != nowDayStr
                              ? () {
                                  start = DateTime.now()
                                      .toString()
                                      .substring(0, 10);
                                  setInnerState(() {});
                                }
                              : null,
                        ),
                        Container(
                          margin: const EdgeInsets.only(right: 10, left: 10),
                          child: const Text("-"),
                        ),
                        RoundedChip(
                          onPressed: () => onDateRangeClick(setInnerState),
                          label: Text(
                            end,
                            style: TextStyle(
                              color: searchEndDate == "" && end == "结束日期"
                                  ? Colors.grey
                                  : null,
                            ),
                          ),
                          avatar: const Icon(Icons.date_range_outlined),
                          deleteIcon: const Icon(
                            Icons.location_on,
                            size: 17,
                            color: Colors.blue,
                          ),
                          deleteButtonTooltipMessage: "定位到今天",
                          onDeleted: end != nowDayStr
                              ? () {
                                  end = DateTime.now()
                                      .toString()
                                      .substring(0, 10);
                                  setInnerState(() {});
                                }
                              : null,
                        ),
                      ],
                    ),
                    //筛选设备
                    Row(
                      children: <Widget>[
                        Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 10),
                          child: const Text(
                            "筛选设备",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        devs.isNotEmpty
                            ? SizedBox(
                                height: 25,
                                width: 25,
                                child: IconButton(
                                  padding: const EdgeInsets.all(2),
                                  tooltip: "清除",
                                  iconSize: 13,
                                  color: Colors.blueGrey,
                                  onPressed: () {
                                    devs.clear();
                                    setInnerState(() {});
                                  },
                                  icon: const Icon(
                                    Icons.cleaning_services_sharp,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Wrap(
                      direction: Axis.horizontal,
                      children: [
                        for (var dev in _allDevices)
                          Container(
                            margin: const EdgeInsets.only(right: 5, bottom: 5),
                            child: RoundedChip(
                              onPressed: () {
                                var guid = dev.guid;
                                if (devs.contains(guid)) {
                                  devs.remove(guid);
                                } else {
                                  devs.add(guid);
                                }
                                setInnerState(() {});
                              },
                              selectedColor: Colors.blue[100],
                              selected: devs.contains(dev.guid),
                              label: Text(dev.name),
                            ),
                          ),
                      ],
                    ),
                    //筛选标签
                    Row(
                      children: <Widget>[
                        Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 10),
                          child: const Text(
                            "筛选标签",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        tags.isNotEmpty
                            ? SizedBox(
                                height: 25,
                                width: 25,
                                child: IconButton(
                                  padding: const EdgeInsets.all(2),
                                  tooltip: "清除",
                                  iconSize: 13,
                                  color: Colors.blueGrey,
                                  onPressed: () {
                                    tags.clear();
                                    setInnerState(() {});
                                  },
                                  icon: const Icon(
                                    Icons.cleaning_services_sharp,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Wrap(
                      direction: Axis.horizontal,
                      children: [
                        for (var tag in _allTagNames)
                          Container(
                            margin: const EdgeInsets.only(right: 5, bottom: 5),
                            child: RoundedChip(
                              onPressed: () {
                                if (tags.contains(tag)) {
                                  tags.remove(tag);
                                } else {
                                  tags.add(tag);
                                }
                                setInnerState(() {});
                              },
                              selectedColor: Colors.blue[100],
                              selected: tags.contains(tag),
                              label: Text(tag),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: App.bgColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _searchFocus,
                autofocus: true,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                    isDense: true,
                    // isCollapsed:true,
                    contentPadding: const EdgeInsets.only(
                      left: 8,
                      right: 8,
                    ),
                    hintText: "搜索",
                    border: InputBorder.none,
                    suffixIcon: InkWell(
                      onTap: () {
                        refreshData();
                      },
                      splashColor: Colors.black12,
                      highlightColor: Colors.black12,
                      borderRadius: BorderRadius.circular(50),
                      child: const Tooltip(
                        message: "搜索",
                        child: Icon(
                          Icons.search_rounded,
                          size: 25,
                        ),
                      ),
                    )),
                onSubmitted: (value) {
                  refreshData();
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 5, right: 5),
              child: IconButton(
                onPressed: () {
                  _showExtendSearchDialog();
                },
                tooltip: "更多筛选项",
                icon: const Icon(Icons.menu_rounded),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
        child: Column(
          children: [
            const SizedBox(
              height: 5,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var type in ["全部", "文本", "图片", "富文本", "文件"])
                    Row(
                      children: [
                        RoundedChip(
                          selected: searchType == type,
                          onPressed: () {
                            if (searchType == type) {
                              return;
                            }
                            setState(() {
                              searchType = type;
                            });
                            refreshData();
                          },
                          selectedColor:
                              searchType == type ? Colors.blue[100] : null,
                          label: Text(type),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  return Future.delayed(
                    const Duration(milliseconds: 500),
                    refreshData,
                  );
                },
                child: ListView.builder(
                  itemCount: _list.length,
                  controller: _scrollController,
                  itemBuilder: (context, i) {
                    return Container(
                      padding: const EdgeInsets.only(left: 2, right: 2),
                      constraints:
                          const BoxConstraints(maxHeight: 150, minHeight: 80),
                      child: ClipDataCard(
                        clip: _list[i],
                        onUpdate: () {
                          _list.sort((a, b) => b.data.compareTo(a.data));
                          setState(() {});
                        },
                        onRemove: (int id) {
                          _list.removeWhere((element) => element.data.id == id);
                          setState(() {});
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _showBackToTopButton
          ? FloatingActionButton(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
                Future.delayed(const Duration(milliseconds: 500), () {
                  setState(() {
                    _list = _list.sublist(0, 20);
                  });
                });
              },
              child: const Icon(Icons.arrow_upward), // 可以选择其他图标
            )
          : null,
    );
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
}
