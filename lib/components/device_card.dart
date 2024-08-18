import 'dart:async';

import 'package:clipshare/components/dot.dart';
import 'package:clipshare/components/rounded_chip.dart';
import 'package:clipshare/db/app_db.dart';
import 'package:clipshare/entity/tables/device.dart';
import 'package:clipshare/entity/tables/operation_record.dart';
import 'package:clipshare/entity/version.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/provider/device_info_provider.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/global.dart';
import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';

class DeviceCard extends StatefulWidget {
  final Device? dev;
  final void Function(Device, bool, void Function())? onTap;
  final void Function(Device, bool, void Function())? onLongPress;
  final bool isPaired;
  final bool isSelf;
  final bool isConnected;
  final Version? minVersion;
  final Version? version;
  final bool isForward;

  const DeviceCard({
    super.key,
    required this.dev,
    this.onTap,
    this.onLongPress,
    required this.isPaired,
    required this.isConnected,
    required this.isSelf,
    required this.minVersion,
    required this.version,
    this.isForward = false,
  });

  bool get isVersionCompatible => minVersion == null || version == null
      ? true
      : minVersion! <= App.version && version! >= App.minVersion;

  @override
  State<StatefulWidget> createState() {
    return _DeviceCardState();
  }

  DeviceCard copyWith({
    Device? dev,
    void Function(Device, bool, void Function())? onTap,
    void Function(Device, bool, void Function())? onLongPress,
    bool? isPaired,
    bool? isConnected,
    bool? isSelf,
    Version? minVersion,
    Version? version,
    bool? isForward,
  }) {
    isConnected = isConnected ?? this.isConnected;
    return DeviceCard(
      dev: dev ?? this.dev,
      isPaired: isPaired ?? this.isPaired,
      isConnected: isConnected,
      isSelf: isSelf ?? this.isSelf,
      onTap: onTap ?? this.onTap,
      onLongPress: onLongPress ?? this.onLongPress,
      minVersion: !isConnected ? null : minVersion ?? this.minVersion,
      version: !isConnected ? null : version ?? this.version,
      isForward: isForward ?? this.isForward,
    );
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

  ///重命名弹窗
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

  Version get minVersion =>
      App.minVersion > widget.minVersion! ? App.minVersion : widget.minVersion!;

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
          child: IntrinsicHeight(
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
                          Visibility(
                            visible: !_empty && widget.isPaired,
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              child: Dot(
                                radius: 6.0,
                                color: widget.isConnected
                                    ? _connColor
                                    : Colors.grey,
                              ),
                            ),
                          ),
                          RoundedChip(
                            label: Text(_empty ? "    " : widget.dev!.type),
                            backgroundColor: chipColor,
                          ),
                          Visibility(
                            visible: widget.isSelf,
                            child: Container(
                              margin: const EdgeInsets.only(left: 5),
                              child: const RoundedChip(
                                label: Text("本机"),
                                backgroundColor: chipColor,
                              ),
                            ),
                          ),
                          Visibility(
                            visible: widget.isForward,
                            child: Container(
                              margin: const EdgeInsets.only(left: 5),
                              child: const RoundedChip(
                                label: Text("中转"),
                                backgroundColor: chipColor,
                              ),
                            ),
                          ),
                          Visibility(
                            visible: !widget.isVersionCompatible,
                            child: Container(
                              margin: const EdgeInsets.only(left: 5),
                              child: Row(
                                children: <Widget>[
                                  IconButton(
                                    onPressed: () => {
                                      Global.showTipsDialog(
                                        context: context,
                                        text: "与该设备的软件版本不兼容，禁用数据同步功能。"
                                            "\n最低版本要求为 ${minVersion.name}(${minVersion.code})"
                                            "\n当前软件版本为 ${App.version.name}(${App.version.code})",
                                      ),
                                    },
                                    icon: const Icon(
                                      Icons.info_outline,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const Text(
                                    "版本不兼容",
                                    style: TextStyle(
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
