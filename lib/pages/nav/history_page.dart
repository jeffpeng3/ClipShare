import 'dart:convert';
import 'dart:math';

import 'package:clipshare/components/clip_data_card.dart';
import 'package:clipshare/dao/history_dao.dart';
import 'package:clipshare/entity/clip_data.dart';
import 'package:clipshare/entity/message_data.dart';
import 'package:clipshare/entity/tables/history.dart';
import 'package:clipshare/entity/tables/history_tag.dart';
import 'package:clipshare/entity/tables/operation_record.dart';
import 'package:clipshare/entity/tables/operation_sync.dart';
import 'package:clipshare/listeners/clip_listener.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/extension.dart';
import 'package:clipshare/util/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../db/db_util.dart';
import '../../listeners/socket_listener.dart';
import '../../main.dart';

class HistoryPage extends StatefulWidget {
  static final GlobalKey<HistoryPageState> pageKey =
      GlobalKey<HistoryPageState>();

  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => HistoryPageState();
}

class HistoryPageState extends State<HistoryPage>
    with WidgetsBindingObserver
    implements ClipObserver, SyncListener {
  final ScrollController _scrollController = ScrollController();
  final List<ClipData> _list = List.empty(growable: true);
  bool _copyInThisCopy = false;
  int? _minId;
  late HistoryDao _historyDao;
  History? _last;
  var updating = false;

  final String tag = "HistoryPage";

  void debounceSetState(void Function()? func) {
    if (updating) {
      return;
    }
    setState(() {
      updating = true;
    });
    Future.delayed(const Duration(milliseconds: 500)).then((value) {
      updating = false;
      setState(func ?? () {});
    });
  }

  @override
  void initState() {
    super.initState();
    _historyDao = DBUtil.inst.historyDao;
    //更新上次复制的记录
    _historyDao.getLatestLocalClip(App.userId).then((his) {
      _last = his;
      //添加同步监听
      SocketListener.inst.addSyncListener(Module.history, this);
      //刷新列表
      refreshData();
      //剪贴板监听注册
      ClipListener.inst.register(this);
    });
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
    SocketListener.inst.removeSyncListener(Module.history, this);
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

  void _scrollListener() {
    // 判断是否快要滑动到底部
    if (_scrollController.position.extentAfter <= 200) {
      // 滑动到底部的处理逻辑
      if (_minId == null) return;
      _historyDao.getHistoriesPage(App.userId, _minId!).then((list) {
        if (list.isEmpty) return;
        _minId = list[list.length - 1].id;
        _list.addAll(ClipData.fromList(list));
        _sortList();
        debounceSetState(null);
      });
    }
  }

  ///重新加载列表
  void refreshData() {
    _minId = null;
    _list.clear();
    _historyDao.getHistoriesTop20(App.userId).then((list) {
      _list.addAll(ClipData.fromList(list));
      for (int i = 0; i < _list.length; i++) {
        ClipData item = _list[i];
        if (_minId == null) {
          _minId = item.data.id;
        } else {
          _minId = min(_minId!, item.data.id);
        }
        _last = item.data;
      }
      debounceSetState(null);
    });
  }

  void _sortList() {
    _list.sort((a, b) => b.data.compareTo(a.data));
    debounceSetState(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 10,
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
                    routeToSearchOnClickChip: true,
                    onUpdate: () {
                      _sortList();
                    },
                    onRemove: (int id) {
                      _list.removeWhere((element) => element.data.id == id);
                      debounceSetState(null);
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  void onChanged(String content) {
    if (_copyInThisCopy) {
      _copyInThisCopy = false;
      return;
    }
    //和上次复制的内容相同
    if (_last?.content == content) {
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
      size: content.length,
    );
    addData(history, true);
  }

  Future<int> addData(History history, bool shouldSync) {
    var clip = ClipData(history);
    return _historyDao.add(clip.data).then((cnt) {
      if (cnt <= 0) return cnt;
      _last = history;
      //更新页面
      if (_minId == null) {
        _minId = clip.data.id;
      } else {
        _minId = min(_minId!, clip.data.id);
      }
      _list.add(clip);
      _list.sort((a, b) => b.data.compareTo(a.data));
      debounceSetState(null);
      if (!shouldSync) return cnt;
      //添加历史操作记录
      var opRecord = OperationRecord.fromSimple(
        Module.history,
        OpMethod.add,
        history.id.toString(),
      );
      DBUtil.inst.opRecordDao.addAndNotify(opRecord);
      if (history.content.hasUrl) {
        //添加标签
        var tag = HistoryTag(
          App.snowflake.nextId(),
          "链接",
          history.id,
        );
        DBUtil.inst.historyTagDao.add(tag).then((cnt) {
          if (cnt <= 0) return;
          //发送操作记录
          var opRecord = OperationRecord.fromSimple(
            Module.tag,
            OpMethod.add,
            tag.id.toString(),
          );
          DBUtil.inst.opRecordDao.addAndNotify(opRecord);
        });
      }
      return cnt;
    });
  }

  @override
  void ackSync(MessageData msg) {
    var send = msg.send;
    var data = msg.data;
    var opSync =
        OperationSync(opId: data["id"], devId: send.guid, uid: App.userId);
    //记录同步记录
    DBUtil.inst.opSyncDao.add(opSync);
    //更新本地历史记录为已同步
    var hisId = msg.data["hisId"];
    DBUtil.inst.historyDao.setSync(hisId, true);
    Log.debug(tag, hisId);
    for (var clip in _list) {
      if (clip.data.id.toString() == hisId.toString()) {
        clip.data.sync = true;
        debounceSetState(null);
        break;
      }
    }
  }

  @override
  void onSync(MessageData msg) {
    var send = msg.send;
    var opRecord = OperationRecord.fromJson(msg.data);
    Map<String, dynamic> json = jsonDecode(opRecord.data);
    History history = History.fromJson(json);
    history.sync = true;
    if (opRecord.module == Module.historyTop) {
      //更新数据库
      DBUtil.inst.historyDao.setTop(history.id, history.top).then((v) {
        //更新页面
        updatePage(
          (h) => h.id == history.id,
          (his) => his.top = history.top,
        );
      });
      //发送同步确认
      SocketListener.inst.sendData(send, MsgType.ackSync, {
        "id": opRecord.id,
        "hisId": history.id,
        "module": Module.historyTop.moduleName,
      });
      return;
    }
    Future? f;
    switch (opRecord.method) {
      case OpMethod.add:
        f = addData(history, false);
        //不是批量同步时放入本地剪贴板
        if (msg.key != MsgType.missingData) {
          _copyInThisCopy = true;
          Clipboard.setData(ClipboardData(text: history.content));
        }
        break;
      case OpMethod.delete:
        DBUtil.inst.historyDao.delete(history.id).then((cnt) {
          if (cnt == null || cnt == 0) return;
          _list.removeWhere((element) => element.data.id == history.id);
          //删除以后判断是否是最近复制的，如果是，更新_last
          if (_last?.id == history.id) {
            if (_list.isEmpty) {
              _last = null;
            } else {
              _last = _list
                  .reduce(
                    (curr, next) => curr.data.id > next.data.id ? curr : next,
                  )
                  .data;
            }
          }
          debounceSetState(null);
        });
        break;
      case OpMethod.update:
        f = DBUtil.inst.historyDao.updateHistory(history).then((cnt) {
          if (cnt == 0) return;
          var i = _list.indexWhere((element) => element.data.id == history.id);
          if (i == -1) return;
          _list[i] = ClipData(history);
          debounceSetState(null);
        });
        break;
      default:
        return;
    }
    if (f == null) {
      //发送同步确认
      SocketListener.inst.sendData(send, MsgType.ackSync, {
        "id": opRecord.id,
        "hisId": history.id,
        "module": Module.history.moduleName,
      });
    } else {
      f.then((cnt) {
        if (cnt <= 0) return;
        //发送同步确认
        SocketListener.inst.sendData(send, MsgType.ackSync, {
          "id": opRecord.id,
          "hisId": history.id,
          "module": Module.history.moduleName,
        });
      });
    }
  }
}
