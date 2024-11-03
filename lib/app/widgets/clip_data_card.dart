import 'dart:io';

import 'package:clipboard_listener/clipboard_manager.dart';
import 'package:clipboard_listener/enums.dart';
import 'package:clipshare/app/data/repository/entity/clip_data.dart';
import 'package:clipshare/app/data/repository/entity/tables/operation_record.dart';
import 'package:clipshare/app/modules/views/preview_page.dart';
import 'package:clipshare/app/modules/views/tag_edit_page.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/channels/clip_channel.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extension.dart';
import 'package:clipshare/app/widgets/clip_simple_data_content.dart';
import 'package:clipshare/app/widgets/clip_simple_data_extra_info.dart';
import 'package:clipshare/app/widgets/clip_simple_data_header.dart';
import 'package:contextmenu/contextmenu.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file_plus/open_file_plus.dart';

import 'clip_detail_dialog.dart';

class ClipDataCard extends StatefulWidget {
  final ClipData clip;
  final void Function()? onTap;
  final void Function()? onLongPress;
  final void Function()? onDoubleTap;
  final void Function() onUpdate;
  final void Function(ClipData item) onRemoveClicked;
  final bool routeToSearchOnClickChip;
  final bool imageMode;
  final bool selectMode;
  final bool selected;

  const ClipDataCard({
    required this.clip,
    required this.onUpdate,
    required this.onRemoveClicked,
    super.key,
    this.routeToSearchOnClickChip = false,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.imageMode = false,
    this.selectMode = false,
    this.selected = false,
  });

  @override
  State<StatefulWidget> createState() {
    return ClipDataCardState();
  }
}

class ClipDataCardState extends State<ClipDataCard> {
  var _readyDoubleClick = false;
  static const _borderWidth = 2.0;
  static const _borderRadius = 12.0;
  bool _selected = false;

  final dbService = Get.find<DbService>();
  final appConfig = Get.find<ConfigService>();
  final androidChannelService = Get.find<AndroidChannelService>();
  final clipChannelService = Get.find<ClipChannelService>();

  @override
  void initState() {
    super.initState();
  }

  void _showDetail(ClipData chip) {
    if (PlatformExt.isDesktop) {
      _showDetailDialog(chip);
      return;
    }
    _showBottomDetailSheet(chip);
  }

  void _showDetailDialog(ClipData chip) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: null,
          contentPadding: const EdgeInsets.all(0),
          content: ClipDetailDialog(
            dlgContext: context,
            clip: chip,
            onUpdate: widget.onUpdate,
            onRemoveClicked: widget.onRemoveClicked,
          ),
        );
      },
    );
  }

  void _showBottomDetailSheet(ClipData chip) {
    showModalBottomSheet(
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      context: context,
      elevation: 100,
      builder: (BuildContext context) {
        return ClipDetailDialog(
          dlgContext: context,
          clip: chip,
          onUpdate: widget.onUpdate,
          onRemoveClicked: widget.onRemoveClicked,
        );
      },
    );
  }

  void _onTap() {
    if (!PlatformExt.isMobile) {
      return;
    }
    _showDetail(widget.clip);
  }

  @override
  Widget build(BuildContext context) {
    _selected = widget.selected;
    return ContextMenuArea(
      child: Card(
        // color: Colors.white,
        elevation: 0,
        child: InkWell(
          mouseCursor: SystemMouseCursors.basic,
          onTap: () {
            if (widget.selectMode) {
              setState(() {
                _selected = !_selected;
              });
              widget.onTap?.call();
              return;
            }
            if (PlatformExt.isDesktop) {
              widget.onTap?.call();
              return;
            }
            if (widget.onDoubleTap == null) {
              //未设置双击，直接执行单击
              _onTap();
            } else {
              //设置了双击，且已经点击过一次，执行双击逻辑
              if (_readyDoubleClick) {
                widget.onDoubleTap!.call();
                //双击结束，恢复状态
                _readyDoubleClick = false;
              } else {
                _readyDoubleClick = true;
                //设置了双击，但仅点击了一次，延迟一段时间
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (_readyDoubleClick) {
                    //指定时间后仍然没有进行第二次点击，进行单击逻辑
                    _onTap();
                  }
                  //指定时间后无论是否双击，恢复状态
                  _readyDoubleClick = false;
                });
              }
            }
          },
          onLongPress: () {
            widget.onLongPress?.call();
          },
          borderRadius: BorderRadius.circular(_borderRadius),
          child: Container(
            margin: widget.selectMode && _selected
                ? null
                : const EdgeInsets.all(_borderWidth),
            decoration: widget.selectMode && _selected
                ? BoxDecoration(
                    border: Border.all(
                      color: Colors.blue,
                      width: _borderWidth,
                    ),
                    borderRadius: BorderRadius.circular(_borderRadius),
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ClipSimpleDataHeader(
                      clip: widget.clip,
                      routeToSearchOnClickChip: widget.routeToSearchOnClickChip,
                    ),
                  ),
                  widget.imageMode
                      ? IntrinsicHeight(
                          child: GestureDetector(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.file(
                                File(
                                  widget.clip.data.content,
                                ),
                                fit: BoxFit.fitWidth,
                                width: 200,
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PreviewPage(
                                    clip: widget.clip,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Expanded(
                          child: Container(
                            alignment: Alignment.centerLeft,
                            child: ClipSimpleDataContent(
                              clip: widget.clip,
                            ),
                          ),
                        ),
                  ClipSimpleDataExtraInfo(clip: widget.clip),
                ],
              ),
            ),
          ),
        ),
      ),
      builder: (context) => [
        ListTile(
          leading: Icon(
            widget.clip.data.top ? Icons.push_pin : Icons.push_pin_outlined,
            color: Colors.blueGrey,
          ),
          title: Text(widget.clip.data.top ? "取消置顶" : "置顶"),
          onTap: () {
            var id = widget.clip.data.id;
            //置顶取反
            var isTop = !widget.clip.data.top;
            widget.clip.data.top = isTop;
            dbService.historyDao.setTop(id, isTop).then((v) {
              if (v == null || v <= 0) return;
              var opRecord = OperationRecord.fromSimple(
                Module.historyTop,
                OpMethod.update,
                id,
              );
              widget.onUpdate();
              setState(() {});
              Navigator.of(context).pop();
              dbService.opRecordDao.addAndNotify(opRecord);
            });
          },
        ),
        Visibility(
          visible: !widget.clip.isFile,
          child: ListTile(
            leading: const Icon(
              Icons.copy,
              color: Colors.blueGrey,
            ),
            title: const Text("复制内容"),
            onTap: () {
              appConfig.innerCopy = true;
              var type = ClipboardContentType.parse(widget.clip.data.type);
              clipboardManager.copy(type, widget.clip.data.content);
              Navigator.of(context).pop();
            },
          ),
        ),
        Visibility(
          visible: !widget.clip.isFile,
          child: ListTile(
            title: Text(widget.clip.data.sync ? "重新同步" : "同步记录"),
            leading: const Icon(
              Icons.sync,
              color: Colors.blueGrey,
            ),
            onTap: () {
              Navigator.of(context).pop();
              var opRecord = OperationRecord.fromSimple(
                Module.history,
                OpMethod.add,
                widget.clip.data.id.toString(),
              );
              dbService.opRecordDao.addAndNotify(opRecord);
            },
          ),
        ),
        Visibility(
            visible: widget.clip.isFile,
            child: ListTile(
              title: const Text("打开文件"),
              leading: const Icon(
                Icons.file_open,
                color: Colors.blueGrey,
              ),
              onTap: () async {
                Navigator.of(context).pop();
                final file = File(widget.clip.data.content);
                await OpenFile.open(
                  file.normalizePath,
                );
              },
            )),
        Visibility(
          visible: widget.clip.isFile,
          child: ListTile(
            title: const Text("打开所在文件夹"),
            leading: const Icon(
              Icons.folder,
              color: Colors.blueGrey,
            ),
            onTap: () async {
              Navigator.of(context).pop();
              final file = File(widget.clip.data.content);
              await OpenFile.open(
                file.parent.normalizePath,
              );
            },
          ),
        ),
        ListTile(
          title: const Text("标签管理"),
          leading: const Icon(
            Icons.tag,
            color: Colors.blueGrey,
          ),
          onTap: () {
            Get.back();
            TagEditPage.goto(widget.clip.data.id);
          },
        ),
        ListTile(
          leading: const Icon(
            Icons.delete,
            color: Colors.blueGrey,
          ),
          title: const Text("删除"),
          onTap: () {
            Get.back();
            widget.onRemoveClicked(widget.clip);
          },
        ),
      ],
    );
  }

  ///删除数据
  Future<bool> removeData() async {
    var id = widget.clip.data.id;
    //删除tag
    await dbService.historyTagDao.removeAllByHisId(id);
    //删除历史
    return dbService.historyDao.delete(id).then((v) {
      if (v == null || v <= 0) return false;
      //添加删除记录
      var opRecord = OperationRecord.fromSimple(
        Module.history,
        OpMethod.delete,
        id,
      );
      dbService.opRecordDao.addAndNotify(opRecord);
      return true;
    });
  }
}
