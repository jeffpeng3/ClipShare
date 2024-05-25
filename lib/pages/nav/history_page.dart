import 'dart:convert';
import 'dart:io';

import 'package:clipshare/channels/android_channel.dart';
import 'package:clipshare/channels/clip_channel.dart';
import 'package:clipshare/channels/multi_window_channel.dart';
import 'package:clipshare/components/clip_list_view.dart';
import 'package:clipshare/components/loading.dart';
import 'package:clipshare/dao/history_dao.dart';
import 'package:clipshare/db/app_db.dart';
import 'package:clipshare/entity/clip_data.dart';
import 'package:clipshare/entity/message_data.dart';
import 'package:clipshare/entity/tables/history.dart';
import 'package:clipshare/entity/tables/history_tag.dart';
import 'package:clipshare/entity/tables/operation_record.dart';
import 'package:clipshare/entity/tables/operation_sync.dart';
import 'package:clipshare/listeners/clipboard_listener.dart';
import 'package:clipshare/listeners/socket_listener.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/provider/history_tag_provider.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/extension.dart';
import 'package:clipshare/util/file_util.dart';
import 'package:clipshare/util/log.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:refena_flutter/refena_flutter.dart';

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
  final List<ClipData> _list = List.empty(growable: true);
  late HistoryDao _historyDao;
  History? _last;
  static bool updating = false;
  final String tag = "HistoryPage";
  Key? _clipListKey;
  bool _loading = true;

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

  @override
  void initState() {
    super.initState();
    updating = false;
    _historyDao = AppDb.inst.historyDao;
    //更新上次复制的记录
    updateLatestLocalClip().then((his) {
      _last = his;
      //添加同步监听
      SocketListener.inst.addSyncListener(Module.history, this);
      //刷新列表
      refreshData().then((val) {
        _loading = false;
        debounceSetState();
      });
      //剪贴板监听注册
      ClipboardListener.inst.register(this);
    });
    //监听生命周期
    WidgetsBinding.instance.addObserver(this);
  }

  Future<History?> updateLatestLocalClip() {
    return _historyDao.getLatestLocalClip(App.userId).then((his) {
      _last = his;
      return his;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SocketListener.inst.removeSyncListener(Module.history, this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed && Platform.isAndroid) {
      debounceSetState();
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

  ///重新加载列表
  Future<void> refreshData() {
    _list.clear();
    return _historyDao.getHistoriesTop20(App.userId).then((list) {
      _list.addAll(ClipData.fromList(list));
      for (int i = 0; i < _list.length; i++) {
        ClipData item = _list[i];
        _last = item.data;
      }
      debounceSetState();
    });
  }

  void _sortList() {
    _list.sort((a, b) => b.data.compareTo(a.data));
    debounceSetState();
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Loading()
        : ClipListView(
            key: _clipListKey,
            list: _list,
            onRefreshData: refreshData,
            enableRouteSearch: true,
            onUpdate: _sortList,
            onRemove: (id) {
              _list.removeWhere(
                (element) => element.data.id == id,
              );
              updateLatestLocalClip();
              debounceSetState();
            },
          );
  }

  @override
  Future<void> onChanged(ContentType type, String content) async {
    if (App.innerCopy) {
      App.setInnerCopy(false);
      return;
    }
    //和上次复制的内容相同
    if (_last?.content == content && _last?.type == type.value) {
      return;
    }
    Log.debug("ClipData onChanged", content);
    int size = content.length;
    switch (type) {
      case ContentType.text:
        //文本无特殊实现，此处留空
        break;
      case ContentType.image:
        //如果上次也是复制的图片/文件，判断其md5与本次比较，若相同则跳过
        if (_last?.type == ContentType.image.value) {
          var md51 = await File(_last!.content).md5;
          var md52 = await File(content).md5;
          //两次的图片存在且相同，跳过。
          if (md51 == md52 && md51 != null) {
            return;
          }
        }
        //移动到设置的路径然后删除临时文件
        var tempFile = File(content);
        size = await tempFile.length();
        var newPath =
            "${Platform.isAndroid ? App.androidPrivatePicturesPath : App.settings.fileStorePath}/${tempFile.fileName}";
        var newFile = File(newPath);
        FileUtil.moveFile(content, newPath);
        content = newFile.normalizePath;
        break;
      case ContentType.richText:
        break;
      case ContentType.file:
        break;
      default:
        throw Exception("UnSupport Type: ${type.label}-${type.value}");
    }
    var history = History(
      id: App.snowflake.nextId(),
      uid: App.userId,
      devId: App.devInfo.guid,
      time: DateTime.now().toString(),
      content: content,
      type: type.value,
      size: size,
    );
    addData(history, true);
  }

  Future<int> addData(History history, bool shouldSync) {
    var clip = ClipData(history);
    return _historyDao.add(clip.data).then((cnt) {
      if (cnt <= 0) return cnt;
      notifyCompactWindow();
      _last = history;
      _list.add(clip);
      _list.sort((a, b) => b.data.compareTo(a.data));
      debounceSetState();
      if (!shouldSync) return cnt;
      //添加历史操作记录
      var opRecord = OperationRecord.fromSimple(
        Module.history,
        OpMethod.add,
        history.id.toString(),
      );
      AppDb.inst.opRecordDao.addAndNotify(opRecord);
      if (ContentType.parse(history.type) == ContentType.text) {
        var regulars = jsonDecode(App.settings.tagRegulars)["data"];
        for (var reg in regulars) {
          if (history.content.matchRegExp(reg["regular"])) {
            //添加标签
            var tag = HistoryTag(
              reg["name"],
              history.id,
            );
            context.ref.notifier(HistoryTagProvider.inst).add(tag);
          }
        }
      }
      return cnt;
    });
  }

  @override
  void ackSync(MessageData msg) {
    var send = msg.send;
    var data = msg.data;
    var opSync = OperationSync(
      opId: data["id"],
      devId: send.guid,
      uid: App.userId,
    );
    //记录同步记录
    AppDb.inst.opSyncDao.add(opSync);
    //更新本地历史记录为已同步
    var hisId = msg.data["hisId"];
    AppDb.inst.historyDao.setSync(hisId, true);
    for (var clip in _list) {
      if (clip.data.id.toString() == hisId.toString()) {
        clip.data.sync = true;
        debounceSetState();
        break;
      }
    }
  }

  void notifyCompactWindow() {
    if (App.compactWindow == null) {
      return;
    }
    MultiWindowChannel.notify(App.compactWindow!.windowId).catchError((err) {
      if (err.toString().contains("target window not found")) {
        App.compactWindow = null;
      } else {
        Log.error(tag, err);
      }
    });
  }

  @override
  Future<void> onSync(MessageData msg) async {
    var send = msg.send;
    var opRecord = OperationRecord.fromJson(msg.data);
    Map<String, dynamic> json = jsonDecode(opRecord.data);
    History history = History.fromJson(json);
    history.sync = true;
    if (opRecord.module == Module.historyTop) {
      //更新数据库
      AppDb.inst.historyDao.setTop(history.id, history.top).then((v) {
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
    Future f = Future.value();
    if ([OpMethod.add, OpMethod.update].contains(opRecord.method)) {
      switch (ContentType.parse(history.type)) {
        case ContentType.image:
          var content = jsonDecode(history.content);
          var fileName = content["fileName"];
          var data = content["data"].cast<int>();
          var path = "${App.settings.fileStorePath}/$fileName";
          Log.debug(tag, "saveToPictures ${App.settings.saveToPictures}");
          if (App.settings.saveToPictures) {
            path =
                "${Constants.androidPicturesPath}/${Constants.appName}/$fileName";
            Log.debug(tag, "newPath $path");
          }
          history.content = path;
          await Permission.manageExternalStorage.request();
          await Permission.storage.request();
          var file = File(path);
          if (!file.existsSync()) {
            file.writeAsBytesSync(data);
            if (App.settings.saveToPictures) {
              AndroidChannel.notifyMediaScan(path);
            }
          }
          break;
        default:
          break;
      }
    }
    switch (opRecord.method) {
      case OpMethod.add:
        f = addData(history, false);
        //不是批量同步时放入本地剪贴板
        if (msg.key != MsgType.missingData) {
          App.setInnerCopy(true);
          ClipChannel.copy(history.toJson());
        }
        break;
      case OpMethod.delete:
        AppDb.inst.historyDao.delete(history.id).then((cnt) {
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
          debounceSetState();
        });
        break;
      case OpMethod.update:
        f = AppDb.inst.historyDao.updateHistory(history).then((cnt) {
          if (cnt == 0) return;
          var i = _list.indexWhere((element) => element.data.id == history.id);
          if (i == -1) return;
          _list[i] = ClipData(history);
          debounceSetState();
        });
        break;
      default:
        return;
    }
    notifyCompactWindow();
    f.whenComplete(() {
      //发送同步确认
      SocketListener.inst.sendData(send, MsgType.ackSync, {
        "id": opRecord.id,
        "hisId": history.id,
        "module": Module.history.moduleName,
      });
    });
  }
}
