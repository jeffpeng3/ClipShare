import 'dart:convert';
import 'dart:io';

import 'package:clipboard_listener/clipboard_manager.dart';
import 'package:clipboard_listener/enums.dart';
import 'package:clipshare/app/data/enums/history_content_type.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/data/repository/entity/tables/device.dart';
import 'package:clipshare/app/data/repository/entity/tables/history.dart';
import 'package:clipshare/app/handlers/hot_key_handler.dart';
import 'package:clipshare/app/handlers/sync/file_sync_handler.dart';
import 'package:clipshare/app/listeners/history_data_listener.dart';
import 'package:clipshare/app/listeners/screen_opened_listener.dart';
import 'package:clipshare/app/modules/device_module/device_controller.dart';
import 'package:clipshare/app/modules/history_module/history_controller.dart';
import 'package:clipshare/app/modules/views/windows/online_devices/online_devices_page.dart';
import 'package:clipshare/app/routes/app_pages.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/channels/clip_channel.dart';
import 'package:clipshare/app/services/channels/multi_window_channel.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/db_service.dart';
import 'package:clipshare/app/services/device_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extensions/file_extension.dart';
import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_handler/share_handler.dart';
import 'package:window_manager/window_manager.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class SplashController extends GetxController {
  static const tag = "SplashController";
  final appConfig = Get.find<ConfigService>();
  final dbService = Get.find<DbService>();
  final clipChannelService = Get.find<ClipChannelService>();
  final androidChannelService = Get.find<AndroidChannelService>();
  final devService = Get.find<DeviceService>();
  final devController = Get.find<DeviceController>();

  @override
  void onReady() {
    super.onReady();
    init().then((ignore) {
      // 初始化完成，导航到下一个页面
      if (appConfig.firstStartup && Platform.isAndroid) {
        Get.offNamed(Routes.WELCOME);
      } else {
        Get.offNamed(Routes.HOME);
      }
    }).catchError((err, stack) {
      Global.showTipsDialog(
        context: Get.context!,
        text: "$err\n$stack",
        title: TranslationKey.errorDialogTitle.tr,
      );
    });
  }

  Future<void> init() async {
    //加载配置后初始化窗体配置
    if (Platform.isWindows) {
      await initWindowsManager();
      await initHotKey();
      initMultiWindowEvent();
    }
    if (PlatformExt.isDesktop) {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      launchAtStartup.setup(
        appName: packageInfo.appName,
        appPath: Platform.resolvedExecutable,
      );
      var isLaunchAtStartup = await launchAtStartup.isEnabled();
      if (Platform.isWindows) {
        final startupPaths = <String>[
          Constants.windowsStartUpPath,
        ];
        final userStartupPath = Constants.windowsUserStartUpPath;
        if (userStartupPath != null) {
          startupPaths.add(userStartupPath);
        }
        for (var startupPath in startupPaths) {
          final dir = Directory(startupPath);
          if (!dir.existsSync()) continue;
          final hasShortcut = await dir.existsTargetFileShortcut(
            Platform.resolvedExecutable,
          );
          isLaunchAtStartup = isLaunchAtStartup || hasShortcut;
        }
      }

      appConfig.setLaunchAtStartup(isLaunchAtStartup);
    }
    // 初始化channel
    initChannel();
    initShareHandler();
    initLanguage();
  }

  void initLanguage() {
    appConfig.updateLanguage();
  }

  Future<void> initWindowsManager() async {
    final [width, height] = appConfig.windowSize.split("x").map((e) => e.toDouble()).toList();
    bool useMinimumSize = true;
    // windowManager.setBackgroundColor(Colors.transparent);
    assert(() {
      useMinimumSize = false;
      return true;
    }());
    WindowOptions windowOptions = WindowOptions(
      size: Size(width, height),
      minimumSize: kReleaseMode ? const Size(Constants.showHistoryRightWidth * 1.0, 200) : null,
      center: true,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () {
      if (!appConfig.startMini) {
        windowManager.show();
        windowManager.focus();
      }
    });
    return Future<void>.value();
  }

  ///初始化快捷键
  initHotKey() async {
    await AppHotKeyHandler.unRegisterAll();
    var hotKey = AppHotKeyHandler.toSystemHotKey(appConfig.historyWindowHotKeys);
    AppHotKeyHandler.registerHistoryWindow(hotKey);
    hotKey = AppHotKeyHandler.toSystemHotKey(appConfig.syncFileHotKeys);
    AppHotKeyHandler.registerFileSync(hotKey);
  }

  void initMultiWindowEvent() {
    //处理弹窗事件
    DesktopMultiWindow.setMethodHandler((
      MethodCall call,
      int fromWindowId,
    ) async {
      var args = jsonDecode(call.arguments);
      switch (call.method) {
        case MultiWindowMethod.getHistories:
          int fromId = args["fromId"];
          var historyDao = dbService.historyDao;
          var lst = List<History>.empty();
          if (fromId == 0) {
            lst = await historyDao.getHistoriesTop20(appConfig.userId);
          } else {
            lst = await historyDao.getHistoriesPage(appConfig.userId, fromId);
          }
          var devMap = devService.toIdNameMap();
          devMap[appConfig.devInfo.guid] = TranslationKey.selfDeviceName.tr;
          var res = {
            "list": lst,
            "devInfos": devMap,
          };
          return jsonEncode(res);
        case MultiWindowMethod.copy:
          int id = args["id"];
          dbService.historyDao.getById(id).then(
            (history) async {
              if (history == null) return;
              appConfig.innerCopy = true;
              var type = ClipboardContentType.parse(history.type);
              await clipboardManager.copy(type, history.content);
              clipboardManager.pasteToPreviousWindow();
            },
          );
          break;
        case MultiWindowMethod.getCompatibleOnlineDevices:
          var devices = devController.getCompatibleOnlineDevices();
          Log.info(tag, "devices $devices");
          return jsonEncode(devices);
        case MultiWindowMethod.syncFiles:
          var files = (args["files"] as List<dynamic>).cast<String>();
          var devices = List<Device>.empty(growable: true);
          for (var devMap in (args["devices"] as List<dynamic>)) {
            devices.add(Device.fromJson(devMap));
          }
          Log.info(tag, "files $files");
          Log.info(tag, "devIds $devices");
          FileSyncHandler.sendFiles(
            devices: devices,
            paths: files,
            context: Get.context!,
          );
          break;
        case MultiWindowMethod.storeWindowPos:
          var pos = args["pos"].toString();
          if (appConfig.recordHistoryDialogPosition) {
            print("object");
            appConfig.setHistoryDialogPosition(pos);
          }
      }
      //都不符合，返回空
      return Future.value();
    });
  }

  void initChannel() {
    appConfig.clipChannel.setMethodCallHandler((call) async {
      var arguments = call.arguments;
      switch (call.method) {
        case ClipChannelMethod.ignoreNextCopy:
          appConfig.innerCopy = true;
          break;
        case ClipChannelMethod.setTop:
          int id = arguments['id'];
          bool top = arguments['top'];
          return dbService.historyDao.setTop(id, top).then((cnt) {
            if (cnt != null && cnt > 0) {
              final historyController = Get.find<HistoryController>();
              historyController.updateData(
                (history) => history.id == id,
                (history) => history.top = top,
                true,
              );
              return true;
            }
            return false;
          });
          break;
        case ClipChannelMethod.getHistory:
          int fromId = arguments["fromId"];
          var historyDao = dbService.historyDao;
          var lst = List<History>.empty();
          if (fromId == 0) {
            lst = await historyDao.getHistoriesTop20(appConfig.userId);
          } else {
            lst = await historyDao.getHistoriesPage(appConfig.userId, fromId);
          }
          var contentLst = lst
              .map(
                (e) => {
                  "id": e.id,
                  "content": e.content,
                  "time": e.time,
                  "top": e.top,
                  "type": e.type,
                },
              )
              .toList();
          return Future(() => contentLst);
      }
      return Future(() => false);
    });
    if (Platform.isAndroid) {
      appConfig.androidChannel.setMethodCallHandler((call) async {
        switch (call.method) {
          case AndroidChannelMethod.onScreenOpened:
            ScreenOpenedListener.inst.notify(true);
            break;
          case AndroidChannelMethod.onScreenClosed:
            ScreenOpenedListener.inst.notify(false);
            break;
          case AndroidChannelMethod.onSmsChanged:
            final content = call.arguments["content"]!;
            HistoryDataListener.inst.onChanged(HistoryContentType.sms, content);
            break;
        }
        return Future(() => false);
      });
    }
  }

  Future<void> initShareHandler() async {
    if (!Platform.isAndroid) {
      return;
    }
    final handler = ShareHandlerPlatform.instance;
    appConfig.shareHandlerStream?.cancel();
    appConfig.shareHandlerStream = handler.sharedMediaStream.listen((SharedMedia media) {
      Log.info(tag, media);
      if (media.attachments != null) {
        var files = media.attachments!.where((attachment) => attachment != null).map((attachment) => attachment!.path).toList();
        Log.debug(tag, files);
        if (files.isEmpty) {
          return;
        }
        gotoOnlineDevicesPage(files);
      } else if (media.content != null) {
        Global.showTipsDialog(
          context: Get.context!,
          text: TranslationKey.saveFileToPathForSettingDialogText.tr,
          okText: TranslationKey.save.tr,
          autoDismiss: false,
          onOk: () async {
            var filePath = await androidChannelService.copyFileFromUri(
              media.content!,
              appConfig.fileStorePath,
            );
            if (Get.context!.mounted) {
              Get.back();
            }

            Log.debug(tag, filePath);
            if (filePath != null) {
              gotoOnlineDevicesPage([filePath]);
            }
          },
          onCancel: () {
            Get.back();
          },
        );
      } else {
        Global.showTipsDialog(context: Get.context!, text: TranslationKey.saveFileNotSupportDialogText.tr);
        return;
      }
    });
  }

  void gotoOnlineDevicesPage(List<String> files) {
    var devices = devController.getCompatibleOnlineDevices();
    Navigator.push(
      Get.context!,
      MaterialPageRoute(
        builder: (context) => OnlineDevicesPage(
          showAppBar: true,
          devices: devices,
          onSendClicked: (BuildContext context, List<Device> selectedDevices) {
            FileSyncHandler.sendFiles(
              devices: selectedDevices,
              paths: files,
              context: context,
            );
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
