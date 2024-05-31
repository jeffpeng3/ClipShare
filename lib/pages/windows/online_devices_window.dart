import 'dart:convert';

import 'package:clipshare/channels/multi_window_channel.dart';
import 'package:clipshare/entity/tables/device.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/pages/online_devices_page.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OnlineDevicesWindow extends StatefulWidget {
  final WindowController windowController;
  final Map args;

  const OnlineDevicesWindow({
    super.key,
    required this.windowController,
    required this.args,
  });

  @override
  State<StatefulWidget> createState() {
    return _OnlineDevicesWindowState();
  }
}

class _OnlineDevicesWindowState extends State<OnlineDevicesWindow>
    with WidgetsBindingObserver {
  late final List<String> _syncFiles;
  List<Device> _devices = [];

  @override
  void initState() {
    super.initState();
    _syncFiles = (widget.args["files"] as List<dynamic>).cast<String>();
    //监听生命周期
    WidgetsBinding.instance.addObserver(this);
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.inactive:
        widget.windowController.close();
        break;
      default:
    }
  }

  void refresh() async {
    var json = await MultiWindowChannel.getCompatibleOnlineDevices(0);
    var data = (jsonDecode(json) as List<dynamic>).cast<Map<String, dynamic>>();
    List<Device> devices = List.empty(growable: true);
    for (var dev in data) {
      devices.add(Device.fromJson(dev));
    }
    _devices = devices;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '设备列表',
      theme: App.themeData,
      //当前运行环境配置
      locale: App.locale,
      //程序支持的语言环境配置
      supportedLocales: App.supportedLocales,
      //Material 风格代理配置
      localizationsDelegates: App.localizationsDelegates,
      home: OnlineDevicesPage(
        devices: _devices,
        onSendClicked: (context, selectedDevices) async {
          await MultiWindowChannel.syncFiles(
            App.mainWindowId,
            selectedDevices,
            _syncFiles,
          );
          widget.windowController.close();
        },
      ),
    );
  }
}
