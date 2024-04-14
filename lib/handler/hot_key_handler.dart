import 'dart:math';

import 'package:clipshare/main.dart';
import 'package:clipshare/util/extension.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';

class AppHotKeyHandler {
  static const historyWindow = "HistoryWindow";
  static final Map<String, HotKey> _map = {};

  static HotKey toSystemHotKey(String keyCodes) {
    var [modifiers, key] = keyCodes.split(";");
    var modifyList = modifiers.split(",").map((e) {
      var key = PhysicalKeyboardKey(e.toInt());
      return key.toModify;
    }).toList(growable: true);
    return HotKey(
      key: PhysicalKeyboardKey(key.toInt()),
      modifiers: modifyList,
      scope: HotKeyScope.system,
    );
  }

  static Future<void> registerHistoryWindow(HotKey key) async {
    await unRegister(historyWindow);
    await hotKeyManager.register(
      key,
      keyDownHandler: (hotKey) async {
        var ids = List.empty();
        try {
          ids = await DesktopMultiWindow.getAllSubWindowIds();
        } catch (e) {
          ids = List.empty();
        }
        //只允许弹窗一次
        if (ids.isNotEmpty) {
          await App.compactWindow?.close();
        }
        //createWindow里面的参数必须传
        final window = await DesktopMultiWindow.createWindow("");
        App.compactWindow = window;
        var offset = await screenRetriever.getCursorScreenPoint();
        //多显示器不知道怎么判断鼠标在哪个显示器中，所以默认主显示器
        Size screenSize = (await screenRetriever.getPrimaryDisplay()).size;
        final [width, height] = [355.0, 630.0];
        final maxX = screenSize.width - width;
        final maxY = screenSize.height - height;
        //限制在屏幕范围内
        final [x, y] = [min(maxX, offset.dx), min(maxY, offset.dy)];
        window
          ..setFrame(Offset(x, y) & Size(width, height))
          ..setTitle('历史记录')
          ..show();
      },
    );
    _map[historyWindow] = key;
  }

  static Future<void> unRegister(String name) async {
    if (_map[name] == null) return;
    await hotKeyManager.unregister(_map[name]!);
    _map.remove(name);
  }

  static Future<void> unRegisterAll() async {
    _map.clear();
    await hotKeyManager.unregisterAll();
  }
}
