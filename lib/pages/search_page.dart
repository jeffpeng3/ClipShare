import 'dart:io';

import 'package:clipshare/components/clip_list_view.dart';
import 'package:clipshare/components/loading.dart';
import 'package:clipshare/components/rounded_chip.dart';
import 'package:clipshare/db/db_util.dart';
import 'package:clipshare/entity/clip_data.dart';
import 'package:clipshare/entity/tables/device.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/extension.dart';
import 'package:flutter/material.dart';

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
  List<ClipData> _list = List.empty(growable: true);
  List<Device> _allDevices = List.empty();
  List<String> _allTagNames = List.empty();
  int? _minId;
  final _searchFocus = FocusNode();
  Key? _clipListKey;
  static bool updating = false;
  bool _loading = true;

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
    //初始化搜索参数
    if (widget.devId != null) {
      _selectedDevIds.add(widget.devId!);
    }
    if (widget.tagName != null) {
      _selectedTags.add(widget.tagName!);
    }
    updating = false;
    //加载数据
    refreshData();
  }

  void debounceSetState() {
    if (updating) {
      return;
    }
    updating = true;
    Future.delayed(const Duration(milliseconds: 500)).then((value) {
      updating = false;
      _clipListKey = UniqueKey();
      setState(() {});
    });
  }

  ///重新加载列表
  void refreshData() {
    _list.clear();
    _minId = null;
    //加载所有标签名
    DBUtil.inst.historyTagDao.getAllTagNames().then((lst) {
      _allTagNames = lst;
      debounceSetState();
    });
    //加载所有设备名
    DBUtil.inst.deviceDao.getAllDevices(App.userId).then((lst) {
      var tmpLst = List<Device>.empty(growable: true);
      tmpLst.add(App.device);
      tmpLst.addAll(lst);
      _allDevices = tmpLst;
      debounceSetState();
    });
    _loadData(_minId).then((lst) {
      _list = lst;
      _loading = false;
      debounceSetState();
    });
  }

  Future<List<ClipData>> _loadData(int? minId) {
    //加载搜索结果的前20条
    return DBUtil.inst.historyDao
        .getHistoriesPageByWhere(
      App.userId,
      minId ?? 0,
      _textController.text,
      typeValue,
      _selectedTags.toList(),
      _selectedDevIds.toList(),
      searchStartDate,
      searchEndDate,
    )
        .then((list) {
      if (PlatformExt.isPC) {
        _searchFocus.requestFocus();
      }
      return ClipData.fromList(list);
    });
  }

  bool get showLeftBar =>
      MediaQuery.of(context).size.width >= Constants.showLeftBarWidth;

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
        scrolledUnderElevation: showLeftBar?0:null,
        automaticallyImplyLeading: !showLeftBar,
        backgroundColor: showLeftBar
            ? Colors.transparent
            : Theme.of(context).colorScheme.inversePrimary,
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
                  contentPadding: const EdgeInsets.only(
                    left: 8,
                    right: 8,
                  ),
                  hintText: "搜索",
                  border: showLeftBar
                      ? OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4), // 边框圆角
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 1.0,
                          ), // 边框样式
                        )
                      : InputBorder.none,
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
                  ),
                ),
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
                              _loading = true;
                              searchType = type;
                            });
                            Future.delayed(
                              const Duration(milliseconds: 500),
                              refreshData,
                            );
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
              child: _loading
                  ? const Loading()
                  : ClipListView(
                      key: _clipListKey,
                      list: _list,
                      onRefreshData: refreshData,
                      onLoadMoreData: (minId) {
                        return _loadData(minId);
                      },
                      detailBorderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && Platform.isAndroid) {
      debounceSetState();
    }
  }
}
