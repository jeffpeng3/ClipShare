import 'dart:io';

import 'package:clipshare/app/handlers/permission_handler.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/permission_helper.dart';
import 'package:clipshare/app/widgets/auth_password_input.dart';
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

  //shizuku
  var shizukuHandler = ShizukuPermHandler();

  //悬浮窗权限
  var floatHandler = FloatPermHandler();

  //检查电池优化
  var ignoreBatteryHandler = IgnoreBatteryHandler();
  final hasNotifyPerm = false.obs;
  final hasShizukuPerm = false.obs;
  final hasFloatPerm = false.obs;
  final hasIgnoreBattery = false.obs;
  final hasSmsReadPerm = true.obs;

  //endregion

  //region 生命周期
  @override
  void onInit() {
    super.onInit();
    //监听生命周期
    WidgetsBinding.instance.addObserver(this);
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

  ///检查必要权限
  void checkPermissions() {
    if (Platform.isAndroid) {
      notifyHandler.hasPermission().then((v) {
        hasNotifyPerm.value = v;
      });
      shizukuHandler.hasPermission().then((v) {
        hasShizukuPerm.value = v;
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
