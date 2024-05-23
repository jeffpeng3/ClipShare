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
  const OnlineDevicesPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _OnlineDevicesPageState();
  }
}

class _OnlineDevicesPageState extends State<OnlineDevicesPage> {
  List<Device> _list = List.empty();
  static const tag = "OnlineDevicesPage";

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
    print(json);
    var data = (jsonDecode(json) as List<dynamic>).cast<Map<String, dynamic>>();
    List<Device> devices = List.empty(growable: true);
    for (var dev in data) {
      devices.add(Device.fromJson(dev));
    }
    _list = devices;
    print(_list);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: App.bgColor,
      body: _list.isEmpty
          ? const EmptyContent()
          : ListView.builder(
              itemCount: _list.length,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (ctx, idx) {
                var dev = _list[idx];
                return DeviceCardSimple(
                  dev: dev,
                  onTap: () {
                    Log.info(tag, dev.guid);
                  },
                );
              },
            ),
    );
  }
}
