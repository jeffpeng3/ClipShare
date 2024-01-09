import 'dart:math';

import 'package:clipshare/components/clip_data_card.dart';
import 'package:clipshare/dao/history_dao.dart';
import 'package:clipshare/entity/clip_data.dart';
import 'package:clipshare/entity/message_data.dart';
import 'package:clipshare/entity/tables/history.dart';
import 'package:clipshare/entity/tables/operation_record.dart';
import 'package:clipshare/entity/tables/operation_sync.dart';
import 'package:clipshare/listeners/clip_listener.dart';
import 'package:clipshare/util/global.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../components/clip_detail_dialog.dart';
import '../../dao/operation_sync_dao.dart';
import '../../db/db_util.dart';
import '../../listeners/socket_listener.dart';
import '../../main.dart';
import '../../util/platform_util.dart';

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
  late OperationSyncDao syncHistoryDao;
  bool _copyInThisCopy = false;
  int? _minId;
  final String tag = "HistoryPage";
  final String module = "历史记录";
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    historyDao = DBUtil.inst.historyDao;
    syncHistoryDao = DBUtil.inst.opSyncDao;
    SocketListener.inst.then((inst) => {inst.addSocketListener(this)});
    refreshData();
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
      if (_minId == null) return;
      historyDao.getHistoriesPage(App.userId, _minId!).then((list) {
        if (list.isEmpty) return;
        _minId = list[list.length - 1].id;
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

  ///重新加载列表
  void refreshData() {
    _minId = null;
    _list.clear();
    historyDao.getHistoriesTop20(App.userId).then((list) {
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
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                    title: null,
                                    contentPadding: const EdgeInsets.all(0),
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
                            showDragHandle: true,
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
    Log.debug("ClipData onChanged", content);
    var history = History(
        id: App.snowflake.nextId(),
        uid: App.userId,
        devId: App.devInfo.guid,
        time: DateTime.now().toString(),
        content: content,
        type: 'Text',
        size: content.length);
    //添加操作记录
    DBUtil.inst.opRecordDao.add(OperationRecord(
        id: App.snowflake.nextId(),
        uid: App.userId,
        module: module,
        method: OpMethod.add,
        data: history.id.toString()));
    addData(history);
    SocketListener.inst.then((inst) {
      inst.sendData(null, MsgType.history, history.toJson());
    });
  }

  void addData(History history) {
    var clip = ClipData(history);
    historyDao.add(clip.data);
    if (_minId == null) {
      _minId = clip.data.id;
    } else {
      _minId = min(_minId!, clip.data.id);
    }
    _list.add(clip);
    _list.sort((a, b) => b.data.compareTo(a.data));
    setState(() {});
  }

  @override
  Future<void> onReceived(MessageData msg) async {
    String devId = msg.send.guid;
    switch (msg.key) {
      //接收剪贴板
      case MsgType.history:
        History history = History.fromJson(msg.data);
        history.sync = true;
        addData(history);
        _copyInThisCopy = true;
        Clipboard.setData(ClipboardData(text: history.content));
        //发送同步确认
        SocketListener.inst.then((inst) {
          inst.sendData(msg.send, MsgType.ackSync, {"id": history.id});
        });
        break;
      //确认已同步
      case MsgType.ackSync:
        var hisId = msg.data["id"];
        DBUtil.inst.historyDao.setSync(hisId.toString(), true);
        // DBUtil.inst.operationSyncDao.add(OperationSync(devId: devId, uid:App.userId));
        Log.debug(tag, hisId);
        for (var clip in _list) {
          if (clip.data.id.toString() == hisId.toString()) {
            Log.debug(tag, hisId);
            clip.data.sync = true;
            setState(() {});
            break;
          }
        }
        break;
      //请求未同步数据
      case MsgType.requestSyncMissingData:
        //查找请求方未同步的数据
        historyDao.getMissingHistory(devId).then((lst) {
          SocketListener.inst.then((inst) {
            inst.sendData(msg.send, MsgType.missingData, {"data": lst});
          });
        });
        break;
      //同步缺失数据
      case MsgType.missingData:
        try {
          var data = msg.data["data"] as List;
          for (var item in data) {
            var h = History.fromJson(item);
            h.sync = true;
            await historyDao.add(h).then((v) {
              if (v == 0) {
                Log.debug(tag, "${h.id} 保存失败");
                return;
              }
              //发送同步确认
              SocketListener.inst.then((inst) {
                inst.sendData(msg.send, MsgType.ackSync, {"id": h.id});
              });
            });
          }
        } catch (e, t) {
          Log.debug(tag, e);
          Log.debug(tag, t);
        } finally {
          //同步完成，刷新数据
          refreshData();
        }
        break;
      default:
    }
  }
}
