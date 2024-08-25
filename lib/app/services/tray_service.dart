import 'dart:async';
import 'dart:io';

import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:get/get.dart';
import 'package:tray_manager/tray_manager.dart';

import 'window_service.dart';

class TrayService extends GetxService with TrayListener {
  bool _trayClick = false;
  static const tag = "TrayService";
  final WindowService windowService = Get.find<WindowService>();

  Future<TrayService> init() async {
    await _initTrayManager();
    return this;
  }

  ///初始化托盘
  Future<void> _initTrayManager() async {
    trayManager.addListener(this);
    trayManager.setToolTip(Constants.appName);
    await trayManager.setIcon(
      Platform.isWindows ? Constants.logoIcoPath : Constants.logoPngPath,
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
  void onTrayIconRightMouseDown() async {
    await trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconMouseDown() async {
    //记录是否双击，如果点击了一次，设置trayClick为true，再次点击时验证
    if (_trayClick) {
      _trayClick = false;
      windowService.showApp();
      return;
    }
    _trayClick = true;
    // 创建一个延迟0.2秒执行一次的定时器重置点击为false
    Timer(const Duration(milliseconds: 200), () {
      _trayClick = false;
    });
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    Log.debug(tag, '你选择了${menuItem.label}');
    switch (menuItem.key) {
      case 'show_window':
        windowService.showApp();
        break;
      case 'exit_app':
        windowService.exitApp();
        break;
    }
  }

  @override
  void onClose() {
    trayManager.removeListener(this);
    super.onClose();
  }
}
