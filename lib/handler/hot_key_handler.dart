import 'dart:io';
import 'dart:math';

import 'package:clipshare/channels/common_channel.dart';
import 'package:clipshare/handler/sync/file_syncer.dart';
import 'package:clipshare/listeners/socket_listener.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/extension.dart';
import 'package:clipshare/util/log.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';

class AppHotKeyHandler {
  static const tag = "AppHotKeyHandler";
  static const historyWindow = "HistoryWindow";
  static const fileSync = "fileSync";
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

  /// 历史弹窗
  static Future<void> registerHistoryWindow(HotKey key) async {
    String hotkeyName = historyWindow;
    await unRegister(hotkeyName);
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
    _map[hotkeyName] = key;
  }

  ///同步文件
  static Future<void> registerFileSync(HotKey key) async {
    String hotkeyName = fileSync;
    await unRegister(hotkeyName);
    await hotKeyManager.register(
      key,
      keyDownHandler: (hotKey) async {
        ///快捷键事件
        Log.info(tag, "$fileSync hotkey down");
        var files = await CommonChannel.getSelectedFiles();
        for (var filePath in files) {
          FileSystemEntityType type = await FileSystemEntity.type(filePath);
          switch (type) {
            case FileSystemEntityType.file:
              FileSyncer.sendFile(filePath);
              break;
            default:
          }
        }
      },
    );
    _map[hotkeyName] = key;
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
