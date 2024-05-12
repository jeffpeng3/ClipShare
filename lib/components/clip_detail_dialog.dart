import 'dart:async';
import 'dart:io';

import 'package:clipshare/channels/android_channel.dart';
import 'package:clipshare/components/clip_content_view.dart';
import 'package:clipshare/components/clip_tag_row_view.dart';
import 'package:clipshare/db/app_db.dart';
import 'package:clipshare/entity/tables/operation_record.dart';
import 'package:clipshare/listeners/socket_listener.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/global.dart';
import 'package:clipshare/util/log.dart';
import 'package:flutter/material.dart';

import '../entity/clip_data.dart';

class ClipDetailDialog extends StatefulWidget {
  final ClipData clip;
  final VoidCallback onUpdate;
  final BuildContext dlgContext;
  final void Function(int id) onRemove;

  const ClipDetailDialog({
    required this.clip,
    required this.onUpdate,
    required this.onRemove,
    required this.dlgContext,
    super.key,
  });

  @override
  State<StatefulWidget> createState() {
    return ClipDetailDialogState();
  }
}

class ClipDetailDialogState extends State<ClipDetailDialog> {
  String get tag => "ClipDetailDialog";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 500),
      padding: const EdgeInsets.only(bottom: 30),
      child: Padding(
        padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.only(left: 7, top: 7, bottom: 7),
                  child: const Text(
                    "剪贴板",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.blueGrey,
                      ),
                      onPressed: () {
                        Future removeData() async {
                          var id = widget.clip.data.id;
                          //删除tag
                          await AppDb.inst.historyTagDao.removeAllByHisId(id);
                          //删除历史
                          return AppDb.inst.historyDao.delete(id).then((v) {
                            if (v == null || v <= 0) return 0;
                            //添加删除记录
                            var opRecord = OperationRecord.fromSimple(
                              Module.history,
                              OpMethod.delete,
                              id,
                            );
                            widget.onRemove(id);
                            setState(() {});
                            Navigator.pop(widget.dlgContext);
                            AppDb.inst.opRecordDao.addAndNotify(opRecord);
                            return v;
                          });
                        }

                        Global.showTipsDialog(
                          context: context,
                          text: "确定删除该记录？",
                          title: "删除提示",
                          showCancel: true,
                          showNeutral:
                              widget.clip.isFile || widget.clip.isImage,
                          neutralText: "连带文件删除",
                          onOk: () {
                            removeData();
                          },
                          onNeutral: () async {
                            var n = await removeData();
                            if (n == null ||
                                n <= 0 ||
                                !widget.clip.isImage ||
                                !Platform.isAndroid) {
                              return;
                            }
                            //如果是图片，删除并更新媒体库
                            var file = File(widget.clip.data.content);
                            file.deleteSync();
                            AndroidChannel.notifyMediaScan(
                                widget.clip.data.content);
                          },
                        );
                      },
                      tooltip: "删除记录",
                    ),
                    IconButton(
                      icon: Icon(
                        widget.clip.data.top
                            ? Icons.push_pin
                            : Icons.push_pin_outlined,
                        color: Colors.blueGrey,
                      ),
                      onPressed: () {
                        var id = widget.clip.data.id;
                        //置顶取反
                        var isTop = !widget.clip.data.top;
                        widget.clip.data.top = isTop;

                        AppDb.inst.historyDao.setTop(id, isTop).then((v) {
                          if (v == null || v <= 0) return;
                          var opRecord = OperationRecord.fromSimple(
                            Module.historyTop,
                            OpMethod.update,
                            id,
                          );
                          widget.onUpdate();
                          setState(() {});
                          AppDb.inst.opRecordDao.addAndNotify(opRecord);
                        });
                      },
                      tooltip: widget.clip.data.top ? "取消置顶" : "置顶",
                    ),
                    IconButton(
                      icon: App.innerCopy
                          ? const Icon(
                              Icons.check,
                              color: Colors.blueGrey,
                            )
                          : const Icon(
                              Icons.copy,
                              color: Colors.blueGrey,
                            ),
                      onPressed: () {
                        App.innerCopy = true;
                        setState(() {});
                        // 创建一个延迟0.5秒执行一次的定时器
                        Future.delayed(const Duration(milliseconds: 500), () {
                          App.innerCopy = false;
                          setState(() {});
                        });
                        App.clipChannel
                            .invokeMethod("copy", widget.clip.data.toJson());
                      },
                      tooltip: "复制内容",
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.sync,
                        color: Colors.blueGrey,
                      ),
                      onPressed: () {
                        AppDb.inst.opRecordDao
                            .getByDataId(
                          widget.clip.data.id,
                          Module.history.moduleName,
                          OpMethod.add.name,
                          App.userId,
                        )
                            .then((op) {
                          Log.debug(tag, op.toString());
                          if (op == null) return;
                          op.data = widget.clip.data.toString();
                          SocketListener.inst
                              .sendData(null, MsgType.sync, op.toJson());
                        });
                      },
                      tooltip: widget.clip.data.top ? "重新同步" : "同步记录",
                    ),
                  ],
                ),
              ],
            ),

            /// 标签栏
            ClipTagRowView(hisId: widget.clip.data.id),

            ///剪贴板内容部分
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              margin: const EdgeInsets.only(top: 10),
              child: ClipContentView(
                clipData: widget.clip,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
