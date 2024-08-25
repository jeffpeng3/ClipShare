import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:clipshare/app/services/channels/common_channel.dart';
import 'package:clipshare/app/services/channels/multi_window_channel.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/extension.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
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
        final appConfig = Get.find<ConfigService>();
        var ids = List.empty();
        try {
          ids = await DesktopMultiWindow.getAllSubWindowIds();
        } catch (e) {
          ids = List.empty();
        }
        //只允许弹窗一次
        if (ids.contains(appConfig.compactWindow?.windowId)) {
          await appConfig.compactWindow?.close();
        }
        //createWindow里面的参数必须传
        final window = await DesktopMultiWindow.createWindow(
          jsonEncode({'tag': MultiWindowTag.history}),
        );
        appConfig.compactWindow = window;
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
        final appConfig = Get.find<ConfigService>();
        final commChannelService = Get.find<CommonChannelService>();

        ///快捷键事件
        Log.info(tag, "$fileSync hotkey down");
        var files = await commChannelService.getSelectedFiles();
        List<String> filePaths = List.empty(growable: true);
        for (var filePath in files) {
          FileSystemEntityType type = await FileSystemEntity.type(filePath);
          switch (type) {
            case FileSystemEntityType.file:
              filePaths.add(filePath);
              break;
            default:
          }
        }
        // no files
        if (filePaths.isEmpty) {
          return;
        }

        var ids = List.empty();
        try {
          ids = await DesktopMultiWindow.getAllSubWindowIds();
        } catch (e) {
          ids = List.empty();
        }
        //只允许弹窗一次
        if (ids.contains(appConfig.onlineDevicesWindow?.windowId)) {
          await appConfig.compactWindow?.close();
        }
        //createWindow里面的参数必须传
        final window = await DesktopMultiWindow.createWindow(
          jsonEncode({'tag': MultiWindowTag.devices, "files": filePaths}),
        );
        appConfig.onlineDevicesWindow = window;
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
          ..setTitle('文件同步')
          ..show();
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
