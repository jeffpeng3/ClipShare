import 'package:clipshare/components/round_chip.dart';
import 'package:clipshare/db/db_util.dart';
import 'package:clipshare/entity/clip_data.dart';
import 'package:clipshare/main.dart';
import 'package:flutter/material.dart';

class ClipDataCard extends StatefulWidget {
  final ClipData clip;
  final GestureTapCallback? onTap;

  const ClipDataCard(this.clip, {super.key, this.onTap});

  @override
  State<StatefulWidget> createState() {
    return ClipDataCardState();
  }
}

class ClipDataCardState extends State<ClipDataCard> {
  bool _showSimpleTime = true;
  String _devName = "本机";
  List<String> _tags = List.empty();

  @override
  void initState() {
    super.initState();
    var history = widget.clip.data;
    DBUtil.inst.deviceDao.getById(history.devId, App.userId).then((dev) {
      if (dev == null) return;
      _devName = dev.devName;
      setState(() {});
    });
    DBUtil.inst.historyTagDao.list(history.id).then((lst) {
      _tags = lst.map((e) => e.tagName).toList(growable: false);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: InkWell(
        onTap: () {
          widget.onTap?.call();
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Row(
                children: [
                  //来源设备
                  RoundedChip(
                    avatar: const Icon(Icons.devices_rounded),
                    backgroundColor: const Color(0x1a000000),
                    label: Text(
                      _devName,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  for (var tagName in _tags)
                    Container(
                      margin: const EdgeInsets.only(left: 5),
                      child: RoundedChip(
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
                          : widget.clip.data.time,
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
