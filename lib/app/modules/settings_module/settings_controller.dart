import 'dart:io';

import 'package:clipboard_listener/clipboard_manager.dart';
import 'package:clipboard_listener/enums.dart';
import 'package:clipshare/app/handlers/permission_handler.dart';
import 'package:clipshare/app/routes/app_pages.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/permission_helper.dart';
import 'package:clipshare/app/widgets/auth_password_input.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class SettingsController extends GetxController with WidgetsBindingObserver {
  final appConfig = Get.find<ConfigService>();

  //region 属性
  final tag = "ProfilePage";

  //通知权限
  var notifyHandler = NotifyPermHandler();

  //悬浮窗权限
  var floatHandler = FloatPermHandler();

  //检查电池优化
  var ignoreBatteryHandler = IgnoreBatteryHandler();
  final hasNotifyPerm = false.obs;
  final hasShizukuPerm = false.obs;
  final hasFloatPerm = false.obs;
  final hasIgnoreBattery = false.obs;
  final hasSmsReadPerm = true.obs;

  //region environment status widgets
  final Rx<Widget> envStatusIcon = Rx<Widget>(const Loading(width: 32));
  final Rx<Widget> envStatusTipContent = Rx<Widget>(
    const Text(
      "Loading Environment Status...",
      style: TextStyle(fontSize: 16),
    ),
  );
  final Rx<Widget> envStatusTipDesc = Rx<Widget>(const SizedBox.shrink());
  final Rx<Color?> envStatusBgColor = Rx<Color?>(null);
  final Rx<Widget?> envStatusAction = Rx<Widget?>(null);
  final warningIcon = const Icon(
    Icons.warning,
    size: 40,
  );

  Color get warningBgColor => Theme.of(Get.context!).colorScheme.surface;
  final normalIcon = const Icon(
    Icons.check_circle_outline_outlined,
    size: 40,
    color: Colors.blue,
  );

  //region Shizuku
  final shizukuEnvNormalTipContent = const Text(
    "Shizuku 模式",
    style: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.blueGrey,
    ),
  );
  final shizukuEnvErrorTipContent = const Text(
    "Shizuku 模式",
    style: TextStyle(fontSize: 16),
  );
  final Rx<int?> shizukuVersion = Rx<int?>(null);

  Widget get shizukuEnvNormalTipDesc => Obx(
        () => Text(
          "服务已运行，API ${shizukuVersion.value}",
          style: const TextStyle(fontSize: 14, color: Color(0xff6d6d70)),
        ),
      );
  final shizukuEnvErrorTipDesc = const Text(
    "服务未运行，部分功能不可用",
    style: TextStyle(fontSize: 14),
  );

  //endregion

  //region Root
  final rootEnvNormalTipContent = const Text(
    "Root 模式",
    style: TextStyle(fontSize: 16),
  );
  final rootEnvErrorTipContent = const Text(
    "Root 模式",
    style: TextStyle(fontSize: 16),
  );
  final rootEnvNormalTipDesc = const Text(
    "已授权，服务已运行",
    style: TextStyle(fontSize: 14),
  );
  final rootEnvErrorTipDesc = const Text(
    "服务未运行，部分功能不可用",
    style: TextStyle(fontSize: 14),
  );

  //endregion

  //region Android Pre 10
  final androidPre10TipContent = const Text(
    "无需特殊权限",
    style: TextStyle(fontSize: 16),
  );

  Widget get androidPre10EnvNormalTipDesc => Text(
        "Android ${appConfig.osVersion}",
        style: const TextStyle(fontSize: 14),
      );

  //endregion

  //region ignore
  final ignoreTipContent = const Text(
    "已忽略权限",
    style: TextStyle(fontSize: 16),
  );

  final ignoreTipDesc = const Text(
    "部分功能可能不可用",
    style: TextStyle(fontSize: 14),
  );

  //endregion

  //endregion

  //endregion

  //region 生命周期
  @override
  void onInit() {
    super.onInit();
    //监听生命周期
    WidgetsBinding.instance.addObserver(this);
    envStatusAction.value = IconButton(
      icon: const Icon(Icons.more_horiz_outlined),
      tooltip: "切换工作模式",
      onPressed: onEnvironmentStatusCardActionClick,
    );
    checkPermissions();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      checkPermissions();
    }
  }

  //endregion

  //region 页面方法

  ///EnvironmentStatusCard click
  Future<void> onEnvironmentStatusCardClick() async {
    if (envStatusBgColor.value != warningBgColor) return;
    await clipboardManager.requestPermission(appConfig.workingMode!);
    clipboardManager.stopListening();
    clipboardManager.startListening(startEnv: appConfig.workingMode);
  }

  ///EnvironmentStatusCard action click
  void onEnvironmentStatusCardActionClick() {
    Get.toNamed(Routes.WORKING_MODE_SELECTION);
  }

  ///检查必要权限
  Future<void> checkPermissions([bool restart = false]) async {
    if (!Platform.isAndroid) {
      return;
    }
    notifyHandler.hasPermission().then((v) {
      hasNotifyPerm.value = v;
    });
    floatHandler.hasPermission().then((v) {
      hasFloatPerm.value = v;
    });
    ignoreBatteryHandler.hasPermission().then((v) {
      hasIgnoreBattery.value = v;
    });
    PermissionHelper.testAndroidReadSms().then(
      (granted) {
        //有权限或者不需要读取短信则视为有权限
        hasSmsReadPerm.value = granted || !appConfig.enableSmsSync;
      },
    );
    final mode = appConfig.workingMode;
    bool hasPermission = true;
    bool listening = await clipboardManager.checkIsRunning();
    if (!listening) {
      await Future.delayed(const Duration(seconds: 2), () async {
        listening = await clipboardManager.checkIsRunning();
      });
    }
    switch (mode) {
      case EnvironmentType.shizuku:
        hasPermission = await clipboardManager.checkPermission(mode!);
        envStatusTipContent.value = hasPermission
            ? shizukuEnvNormalTipContent
            : shizukuEnvErrorTipContent;
        envStatusTipDesc.value = hasPermission && listening
            ? shizukuEnvNormalTipDesc
            : shizukuEnvErrorTipDesc;
        if (hasPermission && shizukuVersion.value == null) {
          shizukuVersion.value = await clipboardManager.getShizukuVersion();
        }
        break;
      case EnvironmentType.root:
        hasPermission = await clipboardManager.checkPermission(mode!);
        envStatusTipContent.value = hasPermission && listening
            ? rootEnvNormalTipContent
            : rootEnvErrorTipContent;
        envStatusTipDesc.value = hasPermission && listening
            ? rootEnvNormalTipDesc
            : rootEnvErrorTipDesc;
        break;
      case EnvironmentType.androidPre10:
        hasPermission = true;
        envStatusTipContent.value = androidPre10TipContent;
        envStatusTipDesc.value = androidPre10EnvNormalTipDesc;
        break;
      default:
        hasPermission = true;
        envStatusTipContent.value = ignoreTipContent;
        envStatusTipDesc.value = ignoreTipDesc;
    }
    envStatusIcon.value = hasPermission && listening ? normalIcon : warningIcon;
    envStatusBgColor.value = hasPermission && listening ? null : warningBgColor;
    if (restart) {
      clipboardManager.stopListening();
      clipboardManager.startListening(startEnv: mode);
      checkPermissions();
    }
  }

  ///跳转密码设置页面
  void gotoSetPwd() {
    Navigator.push(
      Get.context!,
      MaterialPageRoute(
        builder: (context) => AuthPasswordInput(
          onFinished: (a, b) => a == b,
          onOk: (input) {
            appConfig.setAppPassword(input);
            return true;
          },
          again: true,
        ),
      ),
    );
  }
//endregion
}
