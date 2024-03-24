import 'package:clipshare/components/rounded_chip.dart';
import 'package:clipshare/db/db_util.dart';
import 'package:clipshare/entity/clip_data.dart';
import 'package:clipshare/entity/tables/operation_record.dart';
import 'package:clipshare/listeners/socket_listener.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/pages/search_page.dart';
import 'package:clipshare/pages/tag_edit_page.dart';
import 'package:clipshare/provider/device_info_provider.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/extension.dart';
import 'package:contextmenu/contextmenu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:refena_flutter/refena_flutter.dart';

import 'clip_detail_dialog.dart';

class ClipDataCard extends StatefulWidget {
  final ClipData clip;
  final void Function() onUpdate;
  final void Function(int id) onRemove;
  final bool routeToSearchOnClickChip;

  const ClipDataCard({
    required this.clip,
    required this.onUpdate,
    required this.onRemove,
    super.key,
    this.routeToSearchOnClickChip = false,
  });

  @override
  State<StatefulWidget> createState() {
    return ClipDataCardState();
  }
}

class ClipDataCardState extends State<ClipDataCard> {
  bool _showSimpleTime = true;
  List<String> _tags = List.empty();
  bool _copy = false;

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
    var history = widget.clip.data;
    DBUtil.inst.historyTagDao.list(history.id).then((lst) {
      _tags = lst.map((e) => e.tagName).toList(growable: false);
      if (mounted) {
        setState(() {});
      }
    });
    return ViewModelBuilder(
      provider: deviceInfoProvider,
      builder: (context, vm) {
        return ContextMenuArea(
          child: Card(
            elevation: 0,
            child: InkWell(
              onTap: () {
                if (!PlatformExt.isPC) {
                  return;
                }
                _showDetail(widget.clip);
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
                      child: Row(
                        children: [
                          //来源设备
                          RoundedChip(
                            avatar: const Icon(Icons.devices_rounded),
                            backgroundColor: const Color(0x1a000000),
                            onPressed: () {
                              if (widget.routeToSearchOnClickChip) {
                                //导航至搜索页面
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SearchPage(
                                        devId: widget.clip.data.devId),
                                  ),
                                );
                              }
                            },
                            label: Text(
                              vm.getName(widget.clip.data.devId),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          //标签
                          for (var tagName in _tags)
                            Container(
                              margin: const EdgeInsets.only(left: 5),
                              child: RoundedChip(
                                onPressed: () {
                                  if (widget.routeToSearchOnClickChip) {
                                    //导航至搜索页面
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SearchPage(tagName: tagName),
                                      ),
                                    );
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
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.clip.data.content,
                              textAlign: TextAlign.left,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        widget.clip.data.top
                            ? const Icon(Icons.push_pin, size: 16)
                            : const SizedBox(width: 0),
                        !widget.clip.data.sync
                            ? const Icon(
                                Icons.sync,
                                size: 16,
                                color: Colors.red,
                              )
                            : const SizedBox(width: 0),
                        GestureDetector(
                          child: Text(
                            _showSimpleTime
                                ? widget.clip.timeStr
                                : widget.clip.data.time.substring(0, 19),
                          ),
                          onTap: () {
                            setState(() {
                              _showSimpleTime = !_showSimpleTime;
                            });
                          },
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 10),
                        ),
                        Text(widget.clip.sizeText),
                      ],
                    ),
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
                DBUtil.inst.historyDao.setTop(id, isTop).then((v) {
                  if (v == null || v <= 0) return;
                  var opRecord = OperationRecord.fromSimple(
                    Module.historyTop,
                    OpMethod.update,
                    id,
                  );
                  widget.onUpdate();
                  setState(() {});
                  Navigator.of(context).pop();
                  DBUtil.inst.opRecordDao.addAndNotify(opRecord);
                });
              },
            ),
            ListTile(
              leading: _copy
                  ? const Icon(
                      Icons.check,
                      color: Colors.blueGrey,
                    )
                  : const Icon(
                      Icons.copy,
                      color: Colors.blueGrey,
                    ),
              title: const Text("复制内容"),
              onTap: () {
                _copy = true;
                setState(() {});
                // 创建一个延迟0.5秒执行一次的定时器
                Future.delayed(const Duration(milliseconds: 500), () {
                  _copy = false;
                  setState(() {});
                  Navigator.of(context).pop();
                });
                Clipboard.setData(
                  ClipboardData(text: widget.clip.data.content),
                );
              },
            ),
            ListTile(
              title: Text(widget.clip.data.top ? "重新同步" : "同步记录"),
              leading: const Icon(
                Icons.sync,
                color: Colors.blueGrey,
              ),
              onTap: () {
                Navigator.of(context).pop();
                DBUtil.inst.opRecordDao
                    .getByDataId(
                  widget.clip.data.id,
                  Module.history.moduleName,
                  OpMethod.add.name,
                  App.userId,
                )
                    .then((op) {
                  if (op == null) return;
                  op.data = widget.clip.data.toString();
                  SocketListener.inst.sendData(null, MsgType.sync, op.toJson());
                });
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TagEditPage(widget.clip.data.id),
                  ),
                ).then((value) {
                  //重新加载标签
                  DBUtil.inst.historyTagDao
                      .list(widget.clip.data.id)
                      .then((lst) {
                    _tags = lst.map((tag) => tag.tagName).toList();
                    setState(() {});
                  });
                });
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete,
                color: Colors.blueGrey,
              ),
              title: const Text("删除"),
              onTap: () {
                var id = widget.clip.data.id;
                //删除tag
                DBUtil.inst.historyTagDao.removeAllByHisId(id);
                //删除历史
                DBUtil.inst.historyDao.delete(id).then((v) {
                  if (v == null || v <= 0) return;
                  //添加删除记录
                  var opRecord = OperationRecord.fromSimple(
                    Module.history,
                    OpMethod.delete,
                    id,
                  );
                  widget.onRemove(id);
                  setState(() {});
                  Navigator.of(context).pop();
                  DBUtil.inst.opRecordDao.addAndNotify(opRecord);
                });
              },
            ),
          ],
        );
      },
    );
  }
}
