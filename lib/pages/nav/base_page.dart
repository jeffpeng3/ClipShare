import 'dart:async';
import 'dart:io';

import 'package:clipshare/dao/device_dao.dart';
import 'package:clipshare/handler/history_top_syncer.dart';
import 'package:clipshare/handler/permission_handler.dart';
import 'package:clipshare/handler/tag_syncer.dart';
import 'package:clipshare/listeners/socket_listener.dart';
import 'package:clipshare/pages/nav/debug_page.dart';
import 'package:clipshare/pages/nav/devices_page.dart';
import 'package:clipshare/pages/nav/history_page.dart';
import 'package:clipshare/pages/nav/setting_page.dart';
import 'package:clipshare/provider/setting_provider.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/log.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../db/db_util.dart';
import '../../main.dart';
import '../search_page.dart';

class BasePage extends StatefulWidget {
  const BasePage({super.key});

  @override
  State<BasePage> createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> with TrayListener, WindowListener {
  int _index = 0;
  List<Widget> pages = List.from([
    HistoryPage(
      key: HistoryPage.pageKey,
    ),
    const DevicesPage(),
    const SettingPage(),
  ]);
  List<BottomNavigationBarItem> navBarItems = List.from(const [
    BottomNavigationBarItem(
      icon: Icon(Icons.history),
      label: '历史记录',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.devices_rounded),
      label: '我的设备',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: '设置',
    ),
  ]);
  late DeviceDao deviceDao;
  bool trayClick = false;
  late TagSyncer _tagSyncer;
  late HistoryTopSyncer _historyTopSyncer;
  late StreamSubscription _networkListener;

  String get tag => "BasePage";

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
    trayManager.setToolTip(Constants.appName);
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
    //检查权限
    var permHandlers = [
      FloatPermHandler(),
      ShizukuPermHandler(),
      NotifyPermHandler(),
    ];
    for (var handler in permHandlers) {
      handler.hasPermission().then((v) {
        if (!v) {
          handler.request();
        }
      });
    }
  }

  /// 初始化通用行为
  void initCommon() async {
    _networkListener = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      Log.debug(tag, "网络变化 -> ${result.name}");
      if (result != ConnectivityResult.none) {
        SocketListener.inst.startDiscoverDevice();
      }
    });
    _tagSyncer = TagSyncer();
    _historyTopSyncer = HistoryTopSyncer();
    //初始化数据库
    deviceDao = DBUtil.inst.deviceDao;
    //进入主页面后标记为不是第一次进入
    context.ref.notifier(settingProvider).setFirstStartup();
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
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (Platform.isAndroid) {
          App.androidChannel.invokeMethod("moveToBg");
        }
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 238, 238, 238),
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Row(
            children: [
              Expanded(
                  child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  navBarItems[_index].icon,
                  const SizedBox(
                    width: 5,
                  ),
                  Text(navBarItems[_index].label!),
                ],
              )),
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
