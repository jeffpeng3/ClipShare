import 'dart:io';

import 'package:clipshare/components/rounded_chip.dart';
import 'package:clipshare/db/db_util.dart';
import 'package:clipshare/entity/clip_data.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/util/extension.dart';
import 'package:clipshare/pages/search_page.dart';
import 'package:flutter/material.dart';

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
  var _device = App.device;
  List<String> _tags = List.empty();

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
    DBUtil.inst.deviceDao.getById(history.devId, App.userId).then((dev) {
      if (dev == null) return;
      _device = dev;
      if (mounted) {
        setState(() {});
      }
    });
    DBUtil.inst.historyTagDao.list(history.id).then((lst) {
      _tags = lst.map((e) => e.tagName).toList(growable: false);
      if (mounted) {
        setState(() {});
      }
    });
    return Card(
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
                              builder: (context) =>
                                  SearchPage(devId: _device.guid),
                            ),
                          );
                        }
                      },
                      label: Text(
                        _device.name,
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
                          : widget.clip.data.time.substring(0,19),
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
    );
  }
}
