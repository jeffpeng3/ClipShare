import 'dart:math';

import 'package:clipshare/components/clip_data_card.dart';
import 'package:clipshare/components/round_chip.dart';
import 'package:clipshare/dao/history_dao.dart';
import 'package:clipshare/entity/clip_data.dart';
import 'package:clipshare/entity/tables/history.dart';
import 'package:clipshare/listener/ClipListener.dart';
import 'package:clipshare/util/print_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../db/db_util.dart';
import '../main.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with WidgetsBindingObserver
    implements ClipObserver {
  final List<ClipData> _list = List.empty(growable: true);
  late HistoryDao historyDao;
  bool _copyInThisCopy = true;
  int? minId;
  List<Map<String, dynamic>> types = const [
    {'icon': Icons.home, 'text': 'home'},
    {'icon': Icons.home, 'text': 'home'},
    {'icon': Icons.home, 'text': 'home'},
    {'icon': Icons.home, 'text': 'home'},
  ];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    historyDao = DBUtil.inst.historyDao;
    historyDao.getHistoriesTop20(App.userId).then((list) {
      _list.addAll(ClipData.fromList(list));
      for (int i = 0; i < _list.length; i++) {
        ClipData item = _list[i];
        if (minId == null) {
          minId = item.data.id;
        } else {
          minId = min(minId!, item.data.id);
        }
      }
      setState(() {});
    });
    ClipListener.instance().register(this);
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

  void _scrollListener() {
    // 判断是否滑动到底部
    if (_scrollController.position.extentAfter <= 200) {
      // 滑动到底部的处理逻辑
      PrintUtil.print('快滑动到底部了！');
      if (minId == null) return;
      historyDao.getHistoriesPage(App.userId, minId!).then((list) {
        PrintUtil.debug("list page", list);
        minId = list[list.length - 1].id;
        _list.addAll(ClipData.fromList(list));
        _list.sort((a, b) => b.data.compareTo(a.data));
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 10,
        ),
        Expanded(
            child: ListView.builder(
                itemCount: _list.length,
                controller: _scrollController,
                itemBuilder: (context, i) {
                  return Container(
                    padding: const EdgeInsets.only(left: 2, right: 2),
                    constraints:
                        const BoxConstraints(maxHeight: 150, minHeight: 80),
                    child: GestureDetector(
                      child: ClipDataCard(_list[i]),
                      onLongPress: () {
                        showModalBottomSheet(
                            isScrollControlled: true,
                            clipBehavior: Clip.antiAlias,
                            context: context,
                            elevation: 100,
                            builder: (BuildContext context) {
                              return Container(
                                constraints:
                                    const BoxConstraints(maxHeight: 400),
                                padding: const EdgeInsets.only(bottom: 30),
                                child: Padding(
                                    padding: const EdgeInsets.only(
                                        top: 8, left: 8, right: 8),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              alignment: Alignment.topLeft,
                                              padding: const EdgeInsets.only(
                                                  left: 7, top: 7, bottom: 7),
                                              child: const Text(
                                                "剪贴板",
                                                style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.w700),
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.copy,
                                                color: Colors.blueGrey,
                                              ),
                                              onPressed: () {
                                                Clipboard.setData(ClipboardData(
                                                    text:
                                                        _list[i].data.content));
                                              },
                                            ),
                                          ],
                                        ),
                                        Container(
                                            child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: [
                                              RoundedClip(
                                                label: Text(
                                                  "#标签1",
                                                  style: TextStyle(
                                                      color: Color.fromRGBO(
                                                          49, 49, 49, 1.0)),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 5,
                                              ),
                                              RoundedClip(
                                                label: Text("#标签2"),
                                              ),
                                              SizedBox(
                                                width: 5,
                                              ),
                                              RoundedClip(
                                                label: Text("#标签3"),
                                              ),
                                              SizedBox(
                                                width: 5,
                                              ),
                                              RoundedClip(
                                                label: Text("#标签4"),
                                              ),
                                              SizedBox(
                                                width: 5,
                                              ),
                                              RoundedClip(
                                                label: Text("#标签5"),
                                              ),
                                              SizedBox(
                                                width: 5,
                                              ),
                                              RoundedClip(
                                                label: Text("#标签6"),
                                              ),
                                              SizedBox(
                                                width: 5,
                                              ),
                                              RoundedClip(
                                                label: Text("#标签7"),
                                              ),
                                            ],
                                          ),
                                        )),
                                        Container(
                                            margin: EdgeInsets.only(top: 10),
                                            constraints: const BoxConstraints(
                                                maxHeight: 271),
                                            child: SingleChildScrollView(
                                              clipBehavior: Clip.antiAlias,
                                              child: Container(
                                                alignment: Alignment.topLeft,
                                                child: Text(
                                                  _list[i].data.content,
                                                  textAlign: TextAlign.left,
                                                ),
                                              ),
                                            ))
                                      ],
                                    )),
                              );
                            });
                      },
                    ),
                  );
                }))
      ],
    );
  }

  @override
  void onChanged(String content) {
    if (!_copyInThisCopy) {
      _copyInThisCopy = true;
      return;
    }
    PrintUtil.debug("ClipData onChanged", content);
    var clip = ClipData(History(
        id: App.snowflake.nextId(),
        uid: App.userId,
        devId: App.devInfo.guid,
        time: DateTime.now().toString(),
        content: content,
        type: 'Text',
        size: content.length));
    historyDao.add(clip.data);
    if (minId == null) {
      minId = clip.data.id;
    } else {
      minId = min(minId!, clip.data.id);
    }
    _list.add(clip);
    _list.sort((a, b) => b.data.compareTo(a.data));
    setState(() {});
  }
}
