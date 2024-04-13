import 'dart:async';
import 'dart:io';

import 'package:clipshare/db/app_db.dart';
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

import '../../main.dart';
import '../search_page.dart';

class BasePage extends StatefulWidget {
  const BasePage({super.key});

  static final GlobalKey<_BasePageState> pageKey = GlobalKey<_BasePageState>();

  @override
  State<BasePage> createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> with TrayListener, WindowListener {
  int _index = 0;
  final List<Widget> _pages = List.from([
    HistoryPage(
      key: HistoryPage.pageKey,
    ),
    const DevicesPage(),
    const SettingPage(),
  ]);
  final List<BottomNavigationBarItem> _navBarItems = List.from(const [
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

  List<NavigationRailDestination> get _leftBarItems => _navBarItems
      .map(
        (item) => NavigationRailDestination(
          icon: item.icon,
          label: Text(item.label ?? ""),
        ),
      )
      .toList();
  bool _leftMenuExtend = true;
  bool _trayClick = false;
  late TagSyncer _tagSyncer;
  late HistoryTopSyncer _historyTopSyncer;
  late StreamSubscription _networkListener;
  final _logoImg = Image.asset(
    'assets/images/logo/logo.png',
    width: 24,
    height: 24,
  );

  String get tag => "BasePage";

  bool get _showLeftBar =>
      MediaQuery.of(context).size.width >= Constants.smallScreenWidth;

  ///导航至搜索页面
  void gotoSearchPage(String? devId, String? tagName) {
    if (_showLeftBar) {
      var i = _navBarItems
          .indexWhere((element) => (element.icon as Icon).icon == Icons.search);
      setState(() {
        _index = i;
        _pages[i] = SearchPage(
          key: UniqueKey(),
          devId: devId,
          tagName: tagName,
        );
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchPage(
            key: UniqueKey(),
            devId: devId,
            tagName: tagName,
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    assert(() {
      _navBarItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.bug_report_outlined),
          label: "Debug",
        ),
      );
      _pages.add(const DebugPage());
      return true;
    }());
    // 在构建完成后初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Log.debug(tag, "main created");
      _initCommon();
      if (Platform.isAndroid) {
        _initAndroid();
      }
      if (Platform.isWindows) {
        _initWindows();
      }
    });
  }

  ///初始化托盘
  void _initTrayManager() async {
    trayManager.addListener(this);
    trayManager.setToolTip(Constants.appName);
    await trayManager.setIcon(
      Platform.isWindows
          ? 'assets/images/logo/logo.ico'
          : 'assets/images/logo/logo.png',
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
  void onWindowResized() {
    if (!App.settings.rememberWindowSize) {
      return;
    }
    windowManager.getSize().then((size) {
      context.ref.notifier(settingProvider).setWindowSize(size);
    });
  }

  @override
  void onTrayIconRightMouseDown() async {
    await trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconMouseDown() async {
    //记录是否双击，如果点击了一次，设置trayClick为true，再次点击时验证
    if (_trayClick) {
      _trayClick = false;
      setState(() {});
      showApp();
      return;
    }
    _trayClick = true;
    setState(() {});
    // 创建一个延迟0.2秒执行一次的定时器重置点击为false
    Timer(const Duration(milliseconds: 200), () {
      _trayClick = false;
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
      App.compactWindow?.close();
      windowManager.hide();
      WindowManager.instance.destroy();
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
  void _initWindows() async {
    _initTrayManager();
    windowManager.addListener(this);
    // 添加此行以覆盖默认关闭处理程序
    await windowManager.setPreventClose(true);
    setState(() {});
  }

  ///初始化 initAndroid 平台
  void _initAndroid() {
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
  void _initCommon() async {
    //初始化socket
    SocketListener.inst.init(context.ref);
    _networkListener = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      Log.debug(tag, "网络变化 -> ${result.name}");
      if (result != ConnectivityResult.none) {
        SocketListener.inst.restartDiscoverDevice();
      }
    });
    _tagSyncer = TagSyncer();
    _historyTopSyncer = HistoryTopSyncer();
    //进入主页面后标记为不是第一次进入
    context.ref.notifier(settingProvider).setFirstStartup();
  }

  @override
  void dispose() async {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    _tagSyncer.dispose();
    _historyTopSyncer.dispose();
    _networkListener.cancel();
    super.dispose();
  }

  void _initSearchPageShow() {
    var i = _navBarItems
        .indexWhere((element) => (element.icon as Icon).icon == Icons.search);
    var hasSearchPage = i != -1;
    if (!hasSearchPage && _showLeftBar) {
      var i = _navBarItems
          .indexWhere((e) => (e.icon as Icon).icon == Icons.settings);
      setState(() {
        _navBarItems.insert(
          i,
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "搜索",
          ),
        );
        _pages.insert(
          i,
          SearchPage(
            key: UniqueKey(),
            devId: null,
            tagName: null,
          ),
        );
      });
    }
    if (hasSearchPage && !_showLeftBar) {
      setState(() {
        _pages.removeAt(i);
        _navBarItems.removeAt(i);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _initSearchPageShow();
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (Platform.isAndroid) {
          App.androidChannel.invokeMethod("moveToBg");
        }
      },
      child: Scaffold(
        backgroundColor: App.bgColor,
        appBar: !_showLeftBar
            ? AppBar(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                title: Row(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _navBarItems[_index].icon,
                          const SizedBox(
                            width: 5,
                          ),
                          Text(_navBarItems[_index].label!),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        //导航至搜索页面
                        BasePage.pageKey.currentState
                            ?.gotoSearchPage(null, null);
                      },
                      tooltip: "搜索",
                      icon: const Icon(
                        Icons.search_rounded,
                      ),
                    ),
                  ],
                ),
                automaticallyImplyLeading: false,
              )
            : null,
        body: Row(
          children: [
            _showLeftBar
                ? NavigationRail(
                    leading: _leftMenuExtend
                        ? Row(
                            children: [
                              _logoImg,
                              const SizedBox(
                                width: 10,
                              ),
                              const Text(Constants.appName),
                            ],
                          )
                        : _logoImg,
                    extended: _leftMenuExtend,
                    onDestinationSelected: (i) {
                      _index = i;
                      setState(() {});
                    },
                    minExtendedWidth: 200,
                    destinations: _leftBarItems,
                    selectedIndex: _index,
                    trailing: Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: IconButton(
                            icon: Icon(
                              _leftMenuExtend
                                  ? Icons.keyboard_double_arrow_left_outlined
                                  : Icons.keyboard_double_arrow_right_outlined,
                              color: Colors.blueGrey,
                            ),
                            onPressed: () {
                              setState(() {
                                _leftMenuExtend = !_leftMenuExtend;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: _pages,
              ),
            ),
          ],
        ),
        bottomNavigationBar: !_showLeftBar
            ? BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: _index,
                onTap: (i) => {_index = i, setState(() {})},
                items: _navBarItems,
              )
            : null,
      ),
    );
  }
}
