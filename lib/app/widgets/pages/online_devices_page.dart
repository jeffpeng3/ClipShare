import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/device_card_simple.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnlineDevicesPage extends StatefulWidget {
  final List<Device> devices;
  final bool showAppBar;
  final Function(BuildContext context, List<Device> selectedDevives)
      onSendClicked;

  const OnlineDevicesPage({
    super.key,
    required this.devices,
    required this.onSendClicked,
    this.showAppBar = false,
  });

  @override
  State<StatefulWidget> createState() {
    return _OnlineDevicesPageState();
  }
}

class _OnlineDevicesPageState extends State<OnlineDevicesPage> {
  static const tag = "OnlineDevicesPage";
  final Set<String> _selectedDevIds = {};

  final appConfig = Get.find<ConfigService>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: const Text("文件发送"),
            )
          : null,
      backgroundColor: appConfig.bgColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(6),
            child: Text(
              "请选择要发送的设备",
              style: TextStyle(fontSize: 15),
            ),
          ),
          Expanded(
            child: widget.devices.isEmpty
                ? const EmptyContent()
                : ListView.builder(
                    itemCount: widget.devices.length,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (ctx, idx) {
                      var dev = widget.devices[idx];
                      final selected = _selectedDevIds.contains(dev.guid);
                      return DeviceCardSimple(
                        dev: dev,
                        showBorder: selected,
                        onTap: () {
                          if (selected) {
                            _selectedDevIds.remove(dev.guid);
                          } else {
                            _selectedDevIds.add(dev.guid);
                          }
                          setState(() {});
                          Log.info(tag, dev.guid);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Visibility(
            visible: _selectedDevIds.length < widget.devices.length,
            child: Tooltip(
              message: '全选',
              child: FloatingActionButton(
                shape: const CircleBorder(),
                onPressed: () {
                  for (var dev in widget.devices) {
                    _selectedDevIds.add(dev.guid);
                  }
                  setState(() {});
                },
                child: const Icon(Icons.checklist_rtl_outlined),
              ),
            ),
          ),
          Visibility(
            visible: _selectedDevIds.isNotEmpty,
            child: Container(
              margin: const EdgeInsets.only(left: 10),
              child: Tooltip(
                message: '发送',
                child: FloatingActionButton(
                  shape: const CircleBorder(),
                  onPressed: () {
                    var selectedDevices = widget.devices
                        .where(
                          (dev) => _selectedDevIds.contains(dev.guid),
                        )
                        .toList();
                    widget.onSendClicked(context, selectedDevices);
                  },
                  child: const Icon(Icons.send),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
