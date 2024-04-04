import 'dart:async';

import 'package:clipshare/components/rounded_chip.dart';
import 'package:clipshare/db/app_db.dart';
import 'package:clipshare/entity/tables/device.dart';
import 'package:clipshare/provider/device_info_provider.dart';
import 'package:clipshare/util/constants.dart';
import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';

import '../entity/tables/operation_record.dart';

class DeviceCard extends StatefulWidget {
  final Device? dev;
  final void Function(Device, bool, void Function())? onTap;
  final void Function(Device, bool, void Function())? onLongPress;
  bool isPaired;
  bool isSelf;
  bool isConnected;

  DeviceCard({
    super.key,
    required this.dev,
    this.onTap,
    this.onLongPress,
    this.isPaired = false,
    this.isConnected = false,
    this.isSelf = false,
  });

  @override
  State<StatefulWidget> createState() {
    return _DeviceCardState();
  }
}

class _DeviceCardState extends State<DeviceCard> {
  final Color _connColor = Colors.green;
  bool _empty = true;
  Icon _emptyIcon = const Icon(
    Icons.laptop_windows_outlined,
    color: Colors.grey,
    size: 48,
  );
  int _emptyIconIdx = 0;
  Timer? timer;

  Icon get _currIcon => Constants.devTypeIcons[widget.dev!.type]!;

  void _setTimer() {
    timer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      String key = Constants.devTypeIcons.keys
          .elementAt(_emptyIconIdx % Constants.devTypeIcons.length);
      _emptyIcon = Constants.devTypeIcons[key]!;
      _emptyIconIdx++;
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    _empty = widget.dev == null;
    _setTimer();
    setState(() {});
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _showRenameDialog() {
    var dev = widget.dev!;
    var textController = TextEditingController();
    textController.text = dev.customName ?? "";
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("重命名设备"),
          content: SizedBox(
            width: 300,
            child: TextField(
              autofocus: true,
              controller: textController,
              decoration: const InputDecoration(
                label: Text("请输入"),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () {
                var name = textController.text;
                context.ref
                    .notifier(DeviceInfoProvider.inst)
                    .addOrUpdate(dev..customName = name)
                    .then((res) {
                  if (res) {
                    widget.dev!.customName = name;
                    var opRecord = OperationRecord.fromSimple(
                      Module.device,
                      OpMethod.update,
                      dev.guid,
                    );
                    AppDb.inst.opRecordDao.addAndNotify(opRecord);
                    Navigator.pop(context);
                    setState(() {});
                  }
                });
              },
              child: const Text("保存"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const chipColor = Color.fromARGB(255, 213, 222, 232);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        mouseCursor: SystemMouseCursors.basic,
        onTap: () {
          if (_empty) {
            return;
          }
          widget.onTap
              ?.call(widget.dev!, widget.isConnected, _showRenameDialog);
        },
        onLongPress: () {
          if (_empty) {
            return;
          }
          widget.onLongPress
              ?.call(widget.dev!, widget.isConnected, _showRenameDialog);
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 80,
            child: Row(
              children: [
                _empty ? _emptyIcon : _currIcon,
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _empty
                          ? const RoundedChip(
                              label: Text("                  "),
                              backgroundColor: chipColor,
                            )
                          : Row(
                              children: [
                                Text(
                                  widget.dev!.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 22,
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                widget.isPaired
                                    ? IconButton(
                                        onPressed: () {
                                          _showRenameDialog();
                                        },
                                        icon: const Icon(
                                          Icons.edit_note,
                                        ),
                                        tooltip: "重命名",
                                        visualDensity: VisualDensity.compact,
                                      )
                                    : const SizedBox.shrink(),
                              ],
                            ),
                      const SizedBox(
                        height: 8,
                      ),
                      Row(
                        children: [
                          !_empty && widget.isPaired
                              ? Row(
                                  children: [
                                    Container(
                                      width: 6.0 * 2,
                                      height: 6.0 * 2,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: widget.isConnected
                                            ? _connColor
                                            : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                          RoundedChip(
                            label: Text(_empty ? "    " : widget.dev!.type),
                            backgroundColor: chipColor,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          widget.isSelf
                              ? const RoundedChip(
                                  label: Text("本机"),
                                  backgroundColor: chipColor,
                                )
                              : const SizedBox.shrink(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
