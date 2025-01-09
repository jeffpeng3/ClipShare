import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/device_card_simple.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:flutter/material.dart';

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
              title: Text(TranslationKey.sendFile.tr),
            )
          : null,
      backgroundColor: const Color.fromARGB(255, 238, 238, 238),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
               TranslationKey.onlineDevicesPageSelectDeviceToSend.tr,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          Expanded(
            child: widget.devices.isEmpty
                ? EmptyContent()
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
              message: TranslationKey.selectAll.tr,
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
                message: TranslationKey.send.tr,
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
