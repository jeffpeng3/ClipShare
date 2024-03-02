import 'dart:async';
import 'dart:io';

import 'package:clipshare/dao/device_dao.dart';
import 'package:clipshare/handler/history_top_syncer.dart';
import 'package:clipshare/handler/tag_syncer.dart';
import 'package:clipshare/listeners/socket_listener.dart';
import 'package:clipshare/pages/nav/debug_page.dart';
import 'package:clipshare/pages/nav/devices_page.dart';
import 'package:clipshare/pages/nav/history_page.dart';
import 'package:clipshare/pages/nav/profile_page.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/log.dart';
import 'package:clipshare/util/platform_util.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../db/db_util.dart';
import '../../listeners/clip_listener.dart';
import '../../main.dart';
import '../search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TrayListener, WindowListener {
  int _index = 0;
  List<Widget> pages = List.from([
    HistoryPage(
      key: HistoryPage.pageKey,
    ),
    const DevicesPage(),
    const ProfilePage(),
  ]);
  List<BottomNavigationBarItem> navBarItems = List.from(const [
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
  ]);
  late DeviceDao deviceDao;
  bool trayClick = false;
  late TagSyncer _tagSyncer;
  late HistoryTopSyncer _historyTopSyncer;
  late StreamSubscription _networkListener;

  String get tag => "HomePage";

  // final TrayManager _trayManager = TrayManager.instance;
  @override
  void initState() {
    super.initState();
    assert(() {
      navBarItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.bug_report_outlined),
          label: "Debug",
        ),
      );
      pages.add(const DebugPage());
      return true;
    }());
    // 在构建完成后初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Log.debug(tag, "main created");
      initCommon();
      if (Platform.isAndroid) {
        initAndroid();
      }
      if (Platform.isWindows) {
        initWindows();
      }
    });
  }

  ///初始化托盘
  void initTrayManager() async {
    trayManager.addListener(this);
    trayManager.setToolTip("ClipShare");
    await trayManager.setIcon(
      Platform.isWindows
          ? 'assets/images/logo/logo.ico'
          : 'assets/images/logo/logo.jpg',
    );
    List<MenuItem> items = [
      MenuItem(
        key: 'show_window',
        label: '显示主窗口',
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'exit_app',
        label: '退出程序',
      ),
    ];
    await trayManager.setContextMenu(Menu(items: items));
  }

  @override
  void onWindowClose() {
    // do something
    windowManager.hide();
    Log.debug(tag, "onClose");
  }

  @override
  void onTrayIconRightMouseDown() async {
    await trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconMouseDown() async {
    //记录是否双击，如果点击了一次，设置trayClick为true，再次点击时验证
    if (trayClick) {
      trayClick = false;
      setState(() {});
      showApp();
      return;
    }
    trayClick = true;
    setState(() {});
    // 创建一个延迟0.2秒执行一次的定时器重置点击为false
    Timer(const Duration(milliseconds: 200), () {
      trayClick = false;
      setState(() {});
    });
  }

  void showApp() {
    windowManager.setPreventClose(true).then((value) {
      setState(() {});
      windowManager.show();
    });
  }

  void exitApp() {
    windowManager.setPreventClose(false).then((value) {
      windowManager.close();
    });
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    Log.debug(tag, '你选择了${menuItem.label}');
    switch (menuItem.key) {
      case 'show_window':
        showApp();
        break;
      case 'exit_app':
        exitApp();
        break;
    }
  }

  ///初始化 Windows 平台
  void initWindows() async {
    initTrayManager();
    windowManager.addListener(this);
    // 添加此行以覆盖默认关闭处理程序
    await windowManager.setPreventClose(true);
    setState(() {});
  }

  ///初始化 initAndroid 平台
  void initAndroid() {
    //检查悬浮窗权限
    App.androidChannel
        .invokeMethod("checkAlertWindowPermission")
        .then((hasPermission) {
      Log.debug("checkAlarm", hasPermission);
      if (hasPermission == false) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('悬浮窗权限申请'),
              content: const Text(
                '由于 Android 10 及以上版本的系统不允许后台读取剪贴板，当剪贴板发生变化时应用需要通过读取系统日志以及悬浮窗权限间接进行剪贴板读取。\n\n点击确定跳转页面授权悬浮窗权限',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // 关闭弹窗
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('请授予悬浮窗权限，否则无法后台读取剪贴板'),
                        backgroundColor: Colors.red,
                      ),
                    );
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
    App.androidChannel.setMethodCallHandler((call) {
      Log.debug("androidChannel", call.method);
      switch (call.method) {
        case "onScreenOpened":
          //此处应该发送socket通知同步剪贴板到本机
          SocketListener.inst.sendData(null, MsgType.reqMissingData, {});
          break;
        case "checkMustPermission":
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('必要权限缺失'),
                content: const Text(
                  '请授权必要权限，由于 Android 10 及以上版本的系统不允许后台读取剪贴板，需要依赖 Shizuku 或 Root 权限来提权，否则只能被动接收剪贴板数据而不能发送',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      // 关闭弹窗
                      Navigator.of(context).pop();
                    },
                    child: const Text('再也不说了'),
                  ),
                  TextButton(
                    onPressed: () {
                      // 关闭弹窗
                      Navigator.of(context).pop();
                    },
                    child: const Text('确定'),
                  ),
                ],
              );
            },
          );
          break;
      }
      return Future(() => false);
    });
  }

  /// 初始化通用行为
  void initCommon() async {
    _networkListener = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      Log.debug(tag, "网络变化 -> ${result.name}");
      if (result != ConnectivityResult.none) {
        SocketListener.inst.discoverDevice();
      }
    });
    _tagSyncer = TagSyncer();
    _historyTopSyncer = HistoryTopSyncer();
    //初始化数据库
    deviceDao = DBUtil.inst.deviceDao;
    //接收平台消息
    App.clipChannel.setMethodCallHandler((call) {
      switch (call.method) {
        case "setClipText":
          {
            String text = call.arguments['text'];
            ClipListener.inst.update(text);
            debugPrint("clipboard changed: $text");
            return Future(() => true);
          }
      }
      return Future(() => false);
    });
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    _tagSyncer.destroy();
    _historyTopSyncer.destroy();
    _networkListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    App.context = context;
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (PlatformUtil.isAndroid()) {
          App.androidChannel.invokeMethod("moveToBg");
        }
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 238, 238, 238),
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Row(
            children: [
              Expanded(child: Text(widget.title)),
              IconButton(
                onPressed: () {
                  //导航至搜索页面
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchPage(),
                    ),
                  );
                },
                tooltip: "搜索",
                icon: const Icon(
                  Icons.search_rounded,
                ),
              ),
            ],
          ),
          automaticallyImplyLeading: false,
        ),
        body: IndexedStack(
          index: _index,
          children: pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _index,
          onTap: (i) => {_index = i, setState(() {})},
          items: navBarItems,
        ),
      ),
    );
  }
}
