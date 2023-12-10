import 'dart:io';
import 'dart:math';

import 'package:clipshare/components/clip_data_card.dart';
import 'package:clipshare/components/round_chip.dart';
import 'package:clipshare/dao/history_dao.dart';
import 'package:clipshare/entity/clip_data.dart';
import 'package:clipshare/entity/message_data.dart';
import 'package:clipshare/entity/tables/history.dart';
import 'package:clipshare/listeners/clip_listener.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/print_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../components/clip_detail_dialog.dart';
import '../db/db_util.dart';
import '../listeners/socket_listener.dart';
import '../main.dart';
import '../util/platform_util.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with WidgetsBindingObserver
    implements ClipObserver, SocketObserver {
  final List<ClipData> _list = List.empty(growable: true);
  late HistoryDao historyDao;
  bool _copyInThisCopy = false;
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
    SocketListener.inst.then((inst) => {inst.addSocketListener(this)});
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
    SocketListener.inst.then((inst) => {inst.removeSocketListener(this)});
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
      if (minId == null) return;
      historyDao.getHistoriesPage(App.userId, minId!).then((list) {
        if (list.isEmpty) return;
        minId = list[list.length - 1].id;
        _list.addAll(ClipData.fromList(list));
        _list.sort((a, b) => b.data.compareTo(a.data));
        setState(() {});
      });
    }
  }

  void showDetail(ClipData chip) {
    if (PlatformUtil.isPC()) {
      showDetailDialog(chip);
      return;
    }
    showBottomDetailSheet(chip);
  }

  void showDetailDialog(ClipData chip) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return ClipDetailDialog(clip: chip);
        });
  }

  void showBottomDetailSheet(ClipData chip) {
    showModalBottomSheet(
        isScrollControlled: true,
        clipBehavior: Clip.antiAlias,
        context: context,
        elevation: 100,
        builder: (BuildContext context) {
          return ClipDetailDialog(clip: chip);
        });
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
                      onTapUp: (TapUpDetails details) {
                        PrintUtil.print("onTapUp");
                      },
                      onTapDown: (TapDownDetails details) {
                        PrintUtil.print("onTapDown");
                      },
                      behavior: HitTestBehavior.translucent,
                      child: ClipDataCard(
                        _list[i],
                        onTap: () {
                          if (!PlatformUtil.isPC()) {
                            return;
                          }
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                    title: null,
                                    contentPadding: EdgeInsets.all(0),
                                    content: ClipDetailDialog(clip: _list[i]));
                              });
                        },
                      ),
                      onLongPress: () {
                        if (!PlatformUtil.isMobile()) {
                          return;
                        }

                        showModalBottomSheet(
                            isScrollControlled: true,
                            clipBehavior: Clip.antiAlias,
                            context: context,
                            elevation: 100,
                            builder: (BuildContext context) {
                              return ClipDetailDialog(clip: _list[i]);
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
    if (_copyInThisCopy) {
      _copyInThisCopy = false;
      return;
    }
    PrintUtil.debug("ClipData onChanged", content);
    var history = History(
        id: App.snowflake.nextId(),
        uid: App.userId,
        devId: App.devInfo.guid,
        time: DateTime.now().toString(),
        content: content,
        type: 'Text',
        size: content.length);
    addData(history);
    SocketListener.inst.then((inst) {
      inst.sendMulticastMsg(MsgKey.history, history.toJson());
    });
  }

  void addData(History history) {
    var clip = ClipData(history);
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

  @override
  void onReceived(MessageData data) {
    if (data.key != MsgKey.history) {
      return;
    }
    History history = History.fromJson(data.data);
    history.sync = true;
    addData(history);
    _copyInThisCopy = true;
    Clipboard.setData(ClipboardData(text: history.content));
  }
}
