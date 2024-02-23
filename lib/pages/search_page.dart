import 'dart:math';

import 'package:clipshare/components/rounded_chip.dart';
import 'package:clipshare/db/db_util.dart';
import 'package:clipshare/entity/clip_data.dart';
import 'package:clipshare/main.dart';
import 'package:flutter/material.dart';

import '../components/clip_data_card.dart';
import '../util/log.dart';
import '../util/platform_util.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with WidgetsBindingObserver {
  static const tag = "SearchPage";

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ClipData> _list = List.empty(growable: true);
  List<String> _allTagNames = List.empty();
  bool _copyInThisCopy = false;
  int? _minId;

  ///搜索相关
  final Set<String> _selectedTags = {};
  var searchStartDate = DateTime.now();
  var searchEndDate = DateTime.now();
  var searchType = "全部";

  @override
  void initState() {
    super.initState();
    //监听生命周期
    WidgetsBinding.instance.addObserver(this);
    // 监听滚动事件
    _scrollController.addListener(_scrollListener);
    refreshData();
  }

  void _scrollListener() {
    // 判断是否快要滑动到底部
    if (_scrollController.position.extentAfter <= 200) {
      // 滑动到底部的处理逻辑
      if (_minId == null) return;
      _loadData();
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
    _loadData();
  }

  void _loadData() {
    //加载搜索结果的前20条
    DBUtil.inst.historyDao
        .getHistoriesPageByWhere(
      App.userId,
      _minId ?? 0,
      _textController.text,
      searchType == "全部" ? "" : searchType,
      _selectedTags.toList(),
      // _selectedTags.isEmpty ? "" : "('${_selectedTags.join("','")}')",
      searchStartDate.toString().substring(0, 10),
      searchEndDate.toString().substring(0, 10),
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
        var start = searchStartDate;
        var end = searchEndDate;
        var nowDay = DateTime.now().toString().substring(0, 10);
        var tags = Set<String>.from(_selectedTags);
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
                start: start,
                end: end,
              );
          start = range.start;
          end = range.end;
          state(() {});
        }

        return StatefulBuilder(
          builder: (context, setInnerState) {
            return Container(
              padding: const EdgeInsets.all(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                              searchStartDate = start;
                              searchEndDate = end;
                              _selectedTags.clear();
                              _selectedTags.addAll(tags);
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
                          label: Text(start.toString().substring(0, 10)),
                          avatar: const Icon(Icons.date_range_outlined),
                          deleteIcon: const Icon(
                            Icons.location_on,
                            size: 17,
                            color: Colors.blue,
                          ),
                          deleteButtonTooltipMessage: "定位到今天",
                          onDeleted: start.toString().substring(0, 10) != nowDay
                              ? () {
                                  start = DateTime.now();
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
                          label: Text(end.toString().substring(0, 10)),
                          avatar: const Icon(Icons.date_range_outlined),
                          deleteIcon: const Icon(
                            Icons.location_on,
                            size: 17,
                            color: Colors.blue,
                          ),
                          deleteButtonTooltipMessage: "定位到今天",
                          onDeleted: end.toString().substring(0, 10) != nowDay
                              ? () {
                                  end = DateTime.now();
                                  setInnerState(() {});
                                }
                              : null,
                        ),
                      ],
                    ),
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
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  autofocus: true,
                  decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.only(
                        left: 8,
                        right: 8,
                      ),
                      label: const Text("请输入"),
                      border: const OutlineInputBorder(),
                      suffixIcon: Container(
                        margin: const EdgeInsets.only(right: 5),
                        child: IconButton(
                          tooltip: "搜索",
                          onPressed: () {
                            refreshData();
                          },
                          icon: const Icon(Icons.search_rounded),
                          iconSize: 25,
                        ),
                      )),
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
                    child: GestureDetector(
                      onTapUp: (TapUpDetails details) {
                        Log.debug(tag, "onTapUp");
                      },
                      onTapDown: (TapDownDetails details) {
                        Log.debug(tag, "onTapDown");
                      },
                      behavior: HitTestBehavior.translucent,
                      child: ClipDataCard(
                        _list[i],
                        onTap: () {
                          if (!PlatformUtil.isPC()) {
                            return;
                          }
                        },
                      ),
                      onLongPress: () {
                        if (!PlatformUtil.isMobile()) {
                          return;
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
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
