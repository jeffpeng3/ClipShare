import 'dart:convert';

import 'package:clipshare/channels/multi_window_channel.dart';
import 'package:clipshare/components/device_card_simple.dart';
import 'package:clipshare/components/empty_content.dart';
import 'package:clipshare/entity/tables/device.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/util/log.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OnlineDevicesPage extends StatefulWidget {
  final List<String> syncFiles;
  final Function() onDone;
  const OnlineDevicesPage({super.key, required this.syncFiles, required this.onDone});

  @override
  State<StatefulWidget> createState() {
    return _OnlineDevicesPageState();
  }
}

class _OnlineDevicesPageState extends State<OnlineDevicesPage> {
  List<Device> _list = List.empty();
  static const tag = "OnlineDevicesPage";
  final Set<String> _selectedDevices = {};

  @override
  void initState() {
    super.initState();
    //处理弹窗事件
    DesktopMultiWindow.setMethodHandler((
      MethodCall call,
      int fromWindowId,
    ) async {
      var args = jsonDecode(call.arguments);
      switch (call.method) {
        //更新通知
        case MultiWindowMethod.notify:
          refresh();
          break;
      }
      //都不符合，返回空
      return Future.value();
    });
    refresh();
  }

  void refresh() async {
    var json = await MultiWindowChannel.getCompatibleOnlineDevices(0);
    var data = (jsonDecode(json) as List<dynamic>).cast<Map<String, dynamic>>();
    List<Device> devices = List.empty(growable: true);
    for (var dev in data) {
      devices.add(Device.fromJson(dev));
    }
    _list = devices;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: App.bgColor,
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
            child: _list.isEmpty
                ? const EmptyContent()
                : ListView.builder(
                    itemCount: _list.length,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (ctx, idx) {
                      var dev = _list[idx];
                      final selected = _selectedDevices.contains(dev.guid);
                      return DeviceCardSimple(
                        dev: dev,
                        showBorder: selected,
                        onTap: () {
                          if (selected) {
                            _selectedDevices.remove(dev.guid);
                          } else {
                            _selectedDevices.add(dev.guid);
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
            visible: _selectedDevices.length < _list.length,
            child: Tooltip(
              message: '全选',
              child: FloatingActionButton(
                shape: const CircleBorder(),
                onPressed: () {
                  for (var dev in _list) {
                    _selectedDevices.add(dev.guid);
                  }
                  setState(() {});
                },
                child: const Icon(Icons.checklist_rtl_outlined),
              ),
            ),
          ),
          Visibility(
            visible: _selectedDevices.isNotEmpty,
            child: Container(
              margin: const EdgeInsets.only(left: 10),
              child: Tooltip(
                message: '发送',
                child: FloatingActionButton(
                  shape: const CircleBorder(),
                  onPressed: () async {
                    await MultiWindowChannel.syncFiles(
                      App.mainWindowId,
                      List.from(_selectedDevices),
                      widget.syncFiles,
                    );
                    widget.onDone();
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
