import 'package:clipshare/components/clip_simple_data_content.dart';
import 'package:clipshare/components/clip_simple_data_extra_info.dart';
import 'package:clipshare/components/rounded_chip.dart';
import 'package:clipshare/db/app_db.dart';
import 'package:clipshare/entity/clip_data.dart';
import 'package:clipshare/entity/tables/operation_record.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/pages/nav/base_page.dart';
import 'package:clipshare/pages/tag_edit_page.dart';
import 'package:clipshare/provider/device_info_provider.dart';
import 'package:clipshare/provider/history_tag_provider.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/extension.dart';
import 'package:contextmenu/contextmenu.dart';
import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';

import 'clip_detail_dialog.dart';

class ClipDataCard extends StatefulWidget {
  final ClipData clip;
  final void Function()? onTap;
  final void Function()? onDoubleTap;
  final void Function() onUpdate;
  final void Function(int id) onRemove;
  final bool routeToSearchOnClickChip;

  const ClipDataCard({
    required this.clip,
    required this.onUpdate,
    required this.onRemove,
    super.key,
    this.routeToSearchOnClickChip = false,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  State<StatefulWidget> createState() {
    return ClipDataCardState();
  }
}

class ClipDataCardState extends State<ClipDataCard> {
  var _readyDoubleClick = false;

  @override
  void initState() {
    super.initState();
  }

  void _showDetail(ClipData chip) {
    if (PlatformExt.isPC) {
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
            onRemove: widget.onRemove,
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
          onRemove: widget.onRemove,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ContextMenuArea(
      child: Card(
        elevation: 0,
        child: InkWell(
          mouseCursor: SystemMouseCursors.basic,
          onTap: () {
            if (PlatformExt.isPC) {
              widget.onTap?.call();
              return;
            }
            if (widget.onDoubleTap == null) {
              //未设置双击，直接执行单击
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
                  }
                  //指定时间后无论是否双击，恢复状态
                  _readyDoubleClick = false;
                });
              }
            }
          },
          onLongPress: () {
            if (!PlatformExt.isMobile) {
              return;
            }
            _showDetail(widget.clip);
          },
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ViewModelBuilder(
                    provider: HistoryTagProvider.inst,
                    builder: (context, tagsMap) {
                      var tags = tagsMap.getTagList(widget.clip.data.id);
                      return Row(
                        children: [
                          //来源设备
                          Consumer(
                            builder: (context, ref) {
                              var vm = ref.watch(DeviceInfoProvider.inst);
                              return RoundedChip(
                                avatar: const Icon(Icons.devices_rounded),
                                backgroundColor: const Color(0x1a000000),
                                onPressed: () {
                                  if (widget.routeToSearchOnClickChip) {
                                    //导航至搜索页面
                                    BasePage.pageKey.currentState
                                        ?.gotoSearchPage(
                                      widget.clip.data.devId,
                                      null,
                                    );
                                  }
                                },
                                label: Text(
                                  vm.getName(widget.clip.data.devId),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            },
                          ),
                          //标签
                          for (var tagName in tags)
                            Container(
                              margin: const EdgeInsets.only(left: 5),
                              child: RoundedChip(
                                onPressed: () {
                                  if (widget.routeToSearchOnClickChip) {
                                    //导航至搜索页面
                                    BasePage.pageKey.currentState
                                        ?.gotoSearchPage(null, tagName);
                                  }
                                },
                                backgroundColor: const Color(0x1a000000),
                                avatar: const CircleAvatar(
                                  backgroundColor: Colors.blue,
                                  child: Text(
                                    '#',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                label: Text(
                                  tagName,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                Expanded(
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
            AppDb.inst.historyDao.setTop(id, isTop).then((v) {
              if (v == null || v <= 0) return;
              var opRecord = OperationRecord.fromSimple(
                Module.historyTop,
                OpMethod.update,
                id,
              );
              widget.onUpdate();
              setState(() {});
              Navigator.of(context).pop();
              AppDb.inst.opRecordDao.addAndNotify(opRecord);
            });
          },
        ),
        ListTile(
          leading: const Icon(
            Icons.copy,
            color: Colors.blueGrey,
          ),
          title: const Text("复制内容"),
          onTap: () {
            App.innerCopy = true;
            App.clipChannel.invokeMethod("copy", widget.clip.data.toJson());
            Navigator.of(context).pop();
          },
        ),
        ListTile(
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
            AppDb.inst.opRecordDao.addAndNotify(opRecord);
          },
        ),
        ListTile(
          title: const Text("标签管理"),
          leading: const Icon(
            Icons.tag,
            color: Colors.blueGrey,
          ),
          onTap: () {
            Navigator.of(context).pop();
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
            Navigator.pop(context);
            showDialog(
              context: context,
              builder: (ctx) {
                return AlertDialog(
                  title: const Text("删除提示"),
                  content: const Text("确定删除该记录？"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                      },
                      child: const Text("取消"),
                    ),
                    TextButton(
                      onPressed: () {
                        var id = widget.clip.data.id;
                        //删除tag
                        AppDb.inst.historyTagDao.removeAllByHisId(id);
                        //删除历史
                        AppDb.inst.historyDao.delete(id).then((v) {
                          if (v == null || v <= 0) return;
                          //添加删除记录
                          var opRecord = OperationRecord.fromSimple(
                            Module.history,
                            OpMethod.delete,
                            id,
                          );
                          widget.onRemove(id);
                          AppDb.inst.opRecordDao.addAndNotify(opRecord);
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text("确定"),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}
