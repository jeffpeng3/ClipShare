import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clipshare/app/data/repository/entity/clip_data.dart';
import 'package:clipshare/app/data/repository/entity/message_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/data/repository/entity/tables/history_tag.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_sync.dart';
import 'package:clipshare/app/listeners/clipboard_listener.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/channels/clip_channel.dart';
import 'package:clipshare/app/services/channels/multi_window_channel.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/socket_service.dart';
import 'package:clipshare/app/services/tag_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extension.dart';
import 'package:clipshare/app/utils/file_util.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class HistoryController extends GetxController
    with WidgetsBindingObserver
    implements ClipObserver, SyncListener {
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final sktService = Get.find<SocketService>();
  final multiWindowChannelService = Get.find<MultiWindowChannelService>();
  final androidChannelService = Get.find<AndroidChannelService>();
  final clipChannelService = Get.find<ClipChannelService>();
  final tagService = Get.find<TagService>();

  //region 属性
  final String tag = "HistoryController";

  ///不要直接操作这个list，请操作 _tempList 并执行 debounceUpdate() 方法以进行防抖更新
  final list = List<ClipData>.empty(growable: true).obs;
  History? _last;
  bool updating = false;
  final _loading = true.obs;

  bool get loading => _loading.value;
  Timer? _debounce;

  //防止短时间内频繁刷新ui的临时缓冲列表
  final List<ClipData> _tempList = List.empty(growable: true);

  //endregion

  //region 生命周期
  @override
  void onInit() {
    super.onInit();
    //监听生命周期
    WidgetsBinding.instance.addObserver(this);
    //更新上次复制的记录
    updateLatestLocalClip().then((his) {
      _last = his;
      //添加同步监听
      sktService.addSyncListener(Module.history, this);
      //刷新列表
      refreshData();
      //剪贴板监听注册
      ClipboardListener.inst.register(this);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed && Platform.isAndroid) {
      debounceUpdate();
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    sktService.removeSyncListener(Module.history, this);
    super.dispose();
  }

  //endregion

  //region 页面方法
  ///移除数据
  void removeById(int id) {
    _tempList.removeWhere(
      (item) => item.data.id == id,
    );
    debounceUpdate();
  }

  ///更新页面数据
  void updateData(
    bool Function(History history) where,
    void Function(History history) cb,
  ) {
    for (var i = 0; i < _tempList.length; i++) {
      final item = _tempList[i];
      //查找符合条件的数据
      if (where(item.data)) {
        //更新数据
        cb(item.data);
      }
    }
    sortList();
  }

  ///排序列表
  void sortList() {
    _tempList.sort((a, b) => b.data.compareTo(a.data));
    debounceUpdate();
  }

  ///重新加载列表
  Future<void> refreshData() {
    return dbService.historyDao.getHistoriesTop20(appConfig.userId).then((lst) {
      _tempList.assignAll(ClipData.fromList(lst));
      debounceUpdate();
    });
  }

  ///更新上次复制的内容
  Future<History?> updateLatestLocalClip() {
    return dbService.historyDao
        .getLatestLocalClip(appConfig.userId)
        .then((his) {
      _last = his;
      return his;
    });
  }

  ///防抖更新页面
  void debounceUpdate() {
    // 如果已有计时器，则取消它
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    // 重新设置计时器，延迟 500 毫秒执行
    _debounce = Timer(const Duration(milliseconds: 500), () {
      list.assignAll(_tempList);
      if (loading) {
        _loading.value = false;
      }
      if (appConfig.isHistorySyncing.value) {
        appConfig.isHistorySyncing.value = false;
      }
    });
  }

  ///通知子窗体更新
  void notifyCompactWindow() {
    if (appConfig.compactWindow == null) {
      return;
    }
    multiWindowChannelService
        .notify(appConfig.compactWindow!.windowId)
        .catchError((err) {
      if (err.toString().contains("target window not found")) {
        appConfig.compactWindow = null;
      } else {
        Log.error(tag, err);
      }
    });
  }

  ///添加页面数据
  Future<int> addData(History history, bool shouldSync) {
    var clip = ClipData(history);
    return dbService.historyDao.add(clip.data).then((cnt) {
      if (cnt <= 0) return cnt;
      notifyCompactWindow();
      _last = history;
      _tempList.add(clip);
      sortList();
      if (!shouldSync) return cnt;
      //添加历史操作记录
      var opRecord = OperationRecord.fromSimple(
        Module.history,
        OpMethod.add,
        history.id.toString(),
      );
      dbService.opRecordDao.addAndNotify(opRecord);
      switch (ContentType.parse(history.type)) {
        case ContentType.text:
          var rules = jsonDecode(appConfig.tagRules)["data"];
          for (var rule in rules) {
            if (history.content.matchRegExp(rule["rule"])) {
              //添加标签
              var tag = HistoryTag(
                rule["name"],
                history.id,
              );
              tagService.add(tag);
            }
          }
          break;
        default:
      }
      return cnt;
    });
  }

  //endregion

  //region 同步与监听
  @override
  void ackSync(MessageData msg) {
    var send = msg.send;
    var data = msg.data;
    var opSync = OperationSync(
      opId: data["id"],
      devId: send.guid,
      uid: appConfig.userId,
    );
    //记录同步记录
    dbService.opSyncDao.add(opSync);
    //更新本地历史记录为已同步
    var hisId = msg.data["hisId"];
    dbService.historyDao.setSync(hisId, true);
    for (var clip in _tempList) {
      if (clip.data.id.toString() == hisId.toString()) {
        clip.data.sync = true;
        debounceUpdate();
        break;
      }
    }
  }

  @override
  Future<void> onChanged(ContentType type, String content) async {
    if (appConfig.innerCopy) {
      appConfig.innerCopy = false;
      return;
    }
    //和上次复制的内容相同
    if (_last?.content == content && _last?.type == type.value) {
      return;
    }
    Log.debug(tag, content);
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
            "${Platform.isAndroid ? appConfig.androidPrivatePicturesPath : appConfig.fileStorePath}/${tempFile.fileName}";
        var newFile = File(newPath);
        FileUtil.moveFile(content, newPath);
        content = newFile.normalizePath;
        break;
      case ContentType.richText:
        break;
      case ContentType.file:
        break;
      case ContentType.sms:
        //判断是否符合短信同步规则，符合则继续，否则终止
        var rules = jsonDecode(
          appConfig.smsRules,
        )["data"] as List<dynamic>;
        var hasMatch = false;
        for (var rule in rules) {
          if (content.matchRegExp(rule["rule"])) {
            hasMatch = true;
            break;
          }
        }
        //规则列表不为空且未匹配成功，忽略
        if (rules.isNotEmpty && !hasMatch) {
          return;
        }
        break;
      default:
        throw Exception("UnSupport Type: ${type.label}-${type.value}");
    }
    var history = History(
      id: appConfig.snowflake.nextId(),
      uid: appConfig.userId,
      devId: appConfig.devInfo.guid,
      time: DateTime.now().toString(),
      content: content,
      type: type.value,
      size: size,
    );
    addData(history, true);
  }

  @override
  Future<void> onSync(MessageData msg) async {
    appConfig.isHistorySyncing.value = true;
    var send = msg.send;
    var opRecord = OperationRecord.fromJson(msg.data);
    Map<String, dynamic> json = jsonDecode(opRecord.data);
    History history = History.fromJson(json);
    history.sync = true;
    if (opRecord.module == Module.historyTop) {
      //更新数据库
      dbService.historyDao.setTop(history.id, history.top).then((v) {
        //更新页面
        updateData(
          (h) => h.id == history.id,
          (his) => his.top = history.top,
        );
      });
      //发送同步确认
      sktService.sendData(send, MsgType.ackSync, {
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
          var path = "${appConfig.fileStorePath}/$fileName";
          if (appConfig.saveToPictures) {
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
            if (appConfig.saveToPictures) {
              androidChannelService.notifyMediaScan(path);
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
        //不是缺失数据的同步时放入本地剪贴板
        if (msg.key != MsgType.missingData) {
          appConfig.innerCopy = true;
          clipChannelService.copy(history.toJson());
        }
        break;
      case OpMethod.delete:
        f = dbService.historyDao.delete(history.id).then((cnt) {
          if (cnt == null || cnt == 0) return 0;
          _tempList.removeWhere((element) => element.data.id == history.id);
          //删除以后判断是否是最近复制的，如果是，更新_last
          if (_last?.id == history.id) {
            if (_tempList.isEmpty) {
              _last = null;
            } else {
              _last = _tempList
                  .reduce(
                    (curr, next) => curr.data.id > next.data.id ? curr : next,
                  )
                  .data;
            }
          }
          debounceUpdate();
          return cnt;
        });
        break;
      case OpMethod.update:
        f = dbService.historyDao.updateHistory(history).then((cnt) {
          if (cnt == 0) return 0;
          var i =
              _tempList.indexWhere((element) => element.data.id == history.id);
          if (i == -1) return cnt;
          _tempList[i] = ClipData(history);
          debounceUpdate();
          return cnt;
        });
        break;
      default:
        return;
    }
    f.then((cnt) {
      if (cnt == null && cnt <= 0) return;
      //将同步过来的数据添加到本地操作记录
      dbService.opRecordDao.add(opRecord.copyWith(history.id.toString()));
    });
    notifyCompactWindow();
    f.whenComplete(() {
      //发送同步确认
      sktService.sendData(send, MsgType.ackSync, {
        "id": opRecord.id,
        "hisId": history.id,
        "module": Module.history.moduleName,
      });
    });
  }
//endregion
}
