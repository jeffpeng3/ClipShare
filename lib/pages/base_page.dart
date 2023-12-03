import 'dart:io';

import 'package:clipshare/dao/device_dao.dart';
import 'package:clipshare/entity/dev_info.dart';
import 'package:clipshare/entity/tables/device.dart';
import 'package:clipshare/pages/devices_page.dart';
import 'package:clipshare/pages/history_page.dart';
import 'package:clipshare/pages/profile_page.dart';
import 'package:clipshare/util/print_util.dart';
import 'package:clipshare/util/snowflake.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/db_util.dart';
import '../listener/ClipListener.dart';
import '../main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  List<Widget> pages = const [HistoryPage(), DevicesPage(), ProfilePage()];
  late DeviceDao deviceDao;

  @override
  void initState() {
    super.initState();
    // 在构建完成后初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint("main created");
      initCommon();
      if (Platform.isAndroid) {
        initAndroid();
      }
      if (Platform.isWindows) {
        initWindows();
      }
    });
  }

  ///初始化 Windows 平台
  void initWindows() {}

  ///初始化 initAndroid 平台
  void initAndroid() {
    //检查log权限
    App.androidChannel
        .invokeMethod("checkReadLogsPermission")
        .then((hasPermission) {
      PrintUtil.debug("checkReadLogs", hasPermission);
      if (hasPermission == false) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('日志读取权限申请'),
              content: const Text(
                  '由于 Android 10 及以上版本的系统不允许后台读取剪贴板，当剪贴板发生变化时应用需要通过读取系统日志以及悬浮窗权限间接进行剪贴板读取。\n\n'
                  '通过执行adb命令授权日志读取权限（重启手机后需重新授权）：\n\n'
                  'adb -d shell pm grant top.coclyun.clipshare android.permission.READ_LOGS\n\n'
                  '注意：在应用启动时的系统弹窗中点击 "允许访问"'),
              actions: [
                TextButton(
                  onPressed: () {
                    // 关闭弹窗
                    Navigator.of(context).pop();
                  },
                  child: const Text('我知道了'),
                ),
                TextButton(
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(
                        text:
                            "adb -d shell pm grant top.coclyun.clipshare android.permission.READ_LOGS"));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('复制成功，请通过adb授权'),
                      backgroundColor: Colors.lightBlue,
                    ));
                  },
                  child: const Text('复制命令'),
                ),
              ],
            );
          },
        );
      }
    });
    //检查悬浮窗权限
    App.androidChannel
        .invokeMethod("checkAlertWindowPermission")
        .then((hasPermission) {
      PrintUtil.debug("checkAlarm", hasPermission);
      if (hasPermission == false) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('悬浮窗权限申请'),
              content: const Text(
                  '由于 Android 10 及以上版本的系统不允许后台读取剪贴板，当剪贴板发生变化时应用需要通过读取系统日志以及悬浮窗权限间接进行剪贴板读取。\n\n点击确定跳转页面授权悬浮窗权限'),
              actions: [
                TextButton(
                  onPressed: () {
                    // 关闭弹窗
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('请授予悬浮窗权限，否则无法后台读取剪贴板'),
                      backgroundColor: Colors.red,
                    ));
                  },
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    App.androidChannel
                        .invokeMethod("grantAlertWindowPermission");
                    // 关闭弹窗
                    Navigator.of(context).pop();
                  },
                  child: const Text('去授权'),
                ),
              ],
            );
          },
        );
      }
    });
  }

  /// 初始化通用行为
  void initCommon() async {
    //初始化数据库
    deviceDao = DBUtil.inst.deviceDao;
    //接收平台消息
    App.clipChannel.setMethodCallHandler((call) {
      switch (call.method) {
        case "setClipText":
          {
            String text = call.arguments['text'];
            ClipListener.instance().update(text);
            debugPrint("clipboard changed: $text");
            break;
          }
      }
      return Future(() => "ok");
    });

    //调用平台方法，获取设备信息
    App.commonChannel.invokeMethod("getBaseInfo").then((data) {
      String guid = data['guid'];
      String name = data['dev'];
      String type = data['type'];
      App.devInfo = CurrentDevInfo(guid, name);
      App.snowflake = Snowflake(guid.hashCode);
      deviceDao.getById(guid, App.userId).then((dev) {
        if (dev == null) {
          Device device =
              Device(guid: guid, devName: name, uid: App.userId, type: type);
          deviceDao.add(device);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 238, 238, 238),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: IndexedStack(
        index: _index,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => {_index = i, setState(() {})},
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.devices_rounded),
            label: 'Devices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
