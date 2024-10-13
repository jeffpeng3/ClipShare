import 'dart:io';

import 'package:clipshare/app/handlers/hot_key_handler.dart';
import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/modules/log_module/log_controller.dart';
import 'package:clipshare/app/modules/log_module/log_page.dart';
import 'package:clipshare/app/modules/settings_module/settings_controller.dart';
import 'package:clipshare/app/modules/views/settings/sms_rules_setting_page.dart';
import 'package:clipshare/app/modules/views/settings/tag_rules_setting_page.dart';
import 'package:clipshare/app/modules/views/update_log_page.dart';
import 'package:clipshare/app/routes/app_pages.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/socket_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/utils/extension.dart';
import 'package:clipshare/app/utils/file_util.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/utils/permission_helper.dart';
import 'package:clipshare/app/widgets/authentication_time_setting_dialog.dart';
import 'package:clipshare/app/widgets/dynamic_size_widget.dart';
import 'package:clipshare/app/widgets/environment_status_card.dart';
import 'package:clipshare/app/widgets/hot_key_editor.dart';
import 'package:clipshare/app/widgets/settings/card/setting_card.dart';
import 'package:clipshare/app/widgets/settings/card/setting_card_group.dart';
import 'package:clipshare/app/widgets/settings/text_edit_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class SettingsPage extends GetView<SettingsController> {
  final appConfig = Get.find<ConfigService>();
  final sktService = Get.find<SocketService>();
  final androidChannelService = Get.find<AndroidChannelService>();
  final logTag = "SettingsPage";

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(),
        RefreshIndicator(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: ListView(
              children: [
                //region 环境检测卡片
                Obx(() {
                  return EnvironmentStatusCard(
                    icon: Obx(() => controller.envStatusIcon.value),
                    backgroundColor: controller.envStatusBgColor.value,
                    tipContent: Obx(() => controller.envStatusTipContent.value),
                    tipDesc: Obx(() => controller.envStatusTipDesc.value),
                    action: Obx(() {
                      return controller.envStatusAction.value ??
                          const SizedBox.shrink();
                    }),
                    onTap: controller.onEnvironmentStatusCardClick,
                  );
                }),
                //endregion

                ///region 常规
                Obx(
                  () => SettingCardGroup(
                    groupName: "常规",
                    icon: const Icon(Icons.discount_outlined),
                    cardList: [
                      SettingCard(
                        main: const Text("开机启动"),
                        value: appConfig.launchAtStartup,
                        action: (v) => Switch(
                          value: v,
                          onChanged: (checked) async {
                            PackageInfo packageInfo =
                                await PackageInfo.fromPlatform();
                            final appName = packageInfo.appName;
                            final appPath = Platform.resolvedExecutable;
                            launchAtStartup.setup(
                              appName: appName,
                              appPath: appPath,
                            );
                            var enabled = await launchAtStartup.isEnabled();
                            if (!enabled) {
                              await launchAtStartup.enable();
                            } else {
                              await launchAtStartup.disable();
                            }
                            appConfig.setLaunchAtStartup(!enabled);
                          },
                        ),
                        show: (v) => Platform.isWindows,
                      ),
                      SettingCard(
                        main: const Text("启动时最小化窗口"),
                        value: appConfig.startMini,
                        action: (v) => Switch(
                          value: v,
                          onChanged: (checked) {
                            appConfig.setStartMini(checked);
                          },
                        ),
                        show: (v) => PlatformExt.isPC,
                      ),
                      SettingCard(
                        main: const Text("显示历史记录悬浮窗"),
                        value: appConfig.showHistoryFloat,
                        action: (v) => Switch(
                          value: appConfig.showHistoryFloat,
                          onChanged: (checked) {
                            if (checked) {
                              androidChannelService.showHistoryFloatWindow();
                            } else {
                              androidChannelService.closeHistoryFloatWindow();
                            }
                            HapticFeedback.mediumImpact();
                            appConfig.setShowHistoryFloat(checked);
                          },
                        ),
                        show: (v) => Platform.isAndroid,
                      ),
                      SettingCard(
                        main: const Text("锁定悬浮窗位置"),
                        value: appConfig.lockHistoryFloatLoc,
                        action: (v) => Switch(
                          value: appConfig.lockHistoryFloatLoc,
                          onChanged: (checked) {
                            HapticFeedback.mediumImpact();
                            androidChannelService.lockHistoryFloatLoc(
                              {"loc": checked},
                            );
                            appConfig.setLockHistoryFloatLoc(checked);
                          },
                        ),
                        show: (v) =>
                            Platform.isAndroid && appConfig.showHistoryFloat,
                      ),
                      SettingCard(
                        main: const Text("记住上次窗口大小"),
                        sub: Text(
                          "${appConfig.rememberWindowSize ? "记录值：${appConfig.windowSize}，" : ""}默认值：${Constants.defaultWindowSize}",
                        ),
                        value: appConfig.rememberWindowSize,
                        action: (v) => Switch(
                          value: v,
                          onChanged: (checked) {
                            HapticFeedback.mediumImpact();
                            appConfig.setRememberWindowSize(checked);
                          },
                        ),
                        show: (v) => PlatformExt.isPC,
                      ),
                    ],
                  ),
                ),

                ///endregion

                ///region 权限

                Obx(() => SettingCardGroup(
                      groupName: "权限",
                      icon: const Icon(Icons.admin_panel_settings),
                      cardList: [
                        SettingCard(
                          main: const Text("通知权限"),
                          sub: const Text("用于启动前台服务"),
                          value: controller.hasNotifyPerm.value,
                          action: (val) => Icon(
                            val ? Icons.check_circle : Icons.help,
                            color: val ? Colors.green : Colors.orange,
                          ),
                          show: (v) => Platform.isAndroid && !v,
                          onTap: () {
                            if (!controller.hasNotifyPerm.value) {
                              controller.notifyHandler.request();
                            }
                          },
                        ),
                        SettingCard(
                          main: const Text("悬浮窗权限"),
                          sub: const Text("高版本系统中通过悬浮窗获取剪贴板焦点"),
                          value: controller.hasFloatPerm.value,
                          action: (val) => Icon(
                            val ? Icons.check_circle : Icons.help,
                            color: val ? Colors.green : Colors.orange,
                          ),
                          show: (v) => Platform.isAndroid && !v,
                          onTap: () {
                            if (!controller.hasFloatPerm.value) {
                              controller.floatHandler.request();
                            }
                          },
                        ),
                        SettingCard(
                          main: const Text("电池优化"),
                          sub: const Text("添加电池优化防止被后台系统杀死"),
                          value: controller.hasIgnoreBattery.value,
                          action: (val) => Icon(
                            val ? Icons.check_circle : Icons.help,
                            color: val ? Colors.green : Colors.orange,
                          ),
                          show: (v) => Platform.isAndroid && !v,
                          onTap: () {
                            if (!controller.hasIgnoreBattery.value) {
                              controller.ignoreBatteryHandler.request();
                            }
                          },
                        ),
                        SettingCard(
                          main: const Text("短信读取"),
                          sub: const Text("已开启短信同步功能，请授予短信读取权限"),
                          value: controller.hasSmsReadPerm.value,
                          action: (val) => Icon(
                            val ? Icons.check_circle : Icons.help,
                            color: val ? Colors.green : Colors.orange,
                          ),
                          show: (v) => Platform.isAndroid && !v,
                          onTap: () {
                            PermissionHelper.reqAndroidReadSms();
                          },
                        ),
                      ],
                    )),

                ///endregion

                ///region 发现

                Obx(() => SettingCardGroup(
                      groupName: "发现",
                      icon: const Icon(Icons.wifi),
                      cardList: [
                        SettingCard(
                          main: const Text(
                            "设备名称",
                            maxLines: 1,
                          ),
                          sub: Row(
                            children: [
                              Text(
                                "id: ${appConfig.devInfo.guid}",
                                maxLines: 1,
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              GestureDetector(
                                child: const MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Icon(
                                    Icons.copy,
                                    color: Colors.blueGrey,
                                    size: 15,
                                  ),
                                ),
                                onTap: () async {
                                  HapticFeedback.mediumImpact();
                                  Clipboard.setData(ClipboardData(
                                      text: appConfig.devInfo.guid));
                                  Global.showSnackBarSuc(
                                    context,
                                    "已复制设备id",
                                  );
                                },
                              )
                            ],
                          ),
                          value: appConfig.localName,
                          action: (v) => Text(v),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => TextEditDialog(
                                title: "修改设备名称",
                                labelText: "设备名称",
                                initStr: appConfig.localName,
                                onOk: (str) {
                                  appConfig.setLocalName(str);
                                  Global.showSnackBarSuc(
                                    context,
                                    "修改后重启软件生效",
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        SettingCard(
                          main: const Text(
                            "端口号",
                            maxLines: 1,
                          ),
                          sub: const Text(
                            "默认值 ${Constants.port}。修改后可能无法被自动发现",
                            maxLines: 1,
                          ),
                          value: appConfig.port,
                          action: (v) => Text(v.toString()),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => TextEditDialog(
                                title: "修改端口",
                                labelText: "端口",
                                initStr: appConfig.port.toString(),
                                verify: (str) {
                                  var port = int.tryParse(str);
                                  if (port == null) return false;
                                  return port >= 0 && port <= 65535;
                                },
                                errorText: "端口号范围0-65535",
                                onOk: (str) {
                                  appConfig.setPort(str.toInt());
                                  Global.showSnackBarSuc(
                                    context,
                                    "修改后重启软件生效",
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        SettingCard(
                          main: const Text(
                            "可被发现",
                            maxLines: 1,
                          ),
                          sub: const Text(
                            "可以被其它设备自动发现",
                            maxLines: 1,
                          ),
                          value: appConfig.allowDiscover,
                          action: (v) => Switch(
                            value: v,
                            onChanged: (checked) {
                              HapticFeedback.mediumImpact();
                              appConfig.setAllowDiscover(checked);
                            },
                          ),
                        ),
                        SettingCard(
                          main: Row(
                            children: [
                              const Text(
                                "心跳检测间隔",
                                maxLines: 1,
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Tooltip(
                                message: "说明",
                                child: GestureDetector(
                                  child: const MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Icon(
                                      Icons.info_outline,
                                      color: Colors.blueGrey,
                                      size: 15,
                                    ),
                                  ),
                                  onTap: () async {
                                    Global.showTipsDialog(
                                      context: context,
                                      text: "当设备切换网络时无法自动检测到设备是否掉线\n"
                                          "启用心跳检测将会定时检查设备存活情况。",
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          sub: const Text(
                            "检测设备存活。默认30s，0不检测",
                            maxLines: 1,
                          ),
                          value: appConfig.heartbeatInterval,
                          action: (v) => Text(v <= 0 ? '不检测' : '${v}s'),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => TextEditDialog(
                                title: "心跳间隔",
                                labelText: "心跳间隔",
                                initStr:
                                    "${appConfig.heartbeatInterval <= 0 ? '' : appConfig.heartbeatInterval}",
                                verify: (str) {
                                  var port = int.tryParse(str);
                                  if (port == null) return false;
                                  return true;
                                },
                                errorText: "单位秒，0为禁用检测",
                                onOk: (str) async {
                                  await appConfig.setHeartbeatInterval(str);
                                  var enable = str.toInt() > 0;
                                  Log.debug(
                                      logTag, "${enable ? '启用' : '禁用'}心跳检测");
                                  if (enable) {
                                    sktService.startHeartbeatTest();
                                  } else {
                                    sktService.stopHeartbeatTest();
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    )),

                ///endregion

                ///region 中转

                Obx(() => SettingCardGroup(
                      groupName: "中转",
                      icon: const Icon(Icons.cloud_sync_outlined),
                      cardList: [
                        SettingCard(
                          main: Row(
                            children: [
                              const Text(
                                "启用中转服务器",
                                maxLines: 1,
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Tooltip(
                                message: "下载中转程序",
                                child: GestureDetector(
                                  child: const MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Icon(
                                      Icons.info_outline,
                                      color: Colors.blueGrey,
                                      size: 15,
                                    ),
                                  ),
                                  onTap: () async {
                                    Constants.forwardDownloadUrl.askOpenUrl();
                                  },
                                ),
                              ),
                            ],
                          ),
                          sub: const Text(
                            "中转服务器可在公网环境下进行数据同步",
                            maxLines: 1,
                          ),
                          value: appConfig.enableForward,
                          action: (v) {
                            return Switch(
                              value: v,
                              onChanged: (checked) async {
                                HapticFeedback.mediumImpact();
                                //启用中转服务器前先校验是否填写服务器地址
                                if (appConfig.forwardServer.isNullOrEmpty) {
                                  Global.showSnackBarErr(
                                    context,
                                    "请先设置中转服务器地址",
                                  );
                                  return;
                                }
                                await appConfig.setEnableForward(checked);
                                if (checked) {
                                  sktService.connectForwardServer(true);
                                } else {
                                  sktService.disConnectForwardServer();
                                }
                              },
                            );
                          },
                        ),
                        SettingCard(
                          main: const Text(
                            "中转服务器地址",
                            maxLines: 1,
                          ),
                          sub: const Text(
                            "请使用可信地址或自行搭建",
                            maxLines: 1,
                          ),
                          value: appConfig.forwardServer,
                          action: (v) {
                            String text = "更改";
                            if (appConfig.forwardServer.isNullOrEmpty) {
                              text = "配置";
                            }
                            return TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => TextEditDialog(
                                    title: "配置中转服务器",
                                    labelText: "中转地址",
                                    hint: "格式 ip:port",
                                    initStr: appConfig.forwardServer ?? '',
                                    verify: (str) {
                                      if (str.isNullOrEmpty) return false;
                                      if (!str.contains(":")) return false;
                                      final [ip, port] = str.trim().split(':');
                                      return ip.isIPv4 && port.isPortNot0;
                                    },
                                    errorText: "请输入合法的地址",
                                    onOk: (str) async {
                                      if (str.trim() ==
                                          appConfig.forwardServer) {
                                        return;
                                      }
                                      await appConfig.setForwardServer(str);
                                    },
                                  ),
                                );
                              },
                              child: Text(text),
                            );
                          },
                        ),
                      ],
                    )),

                ///endregion

                ///region 安全设置

                Obx(() => SettingCardGroup(
                      groupName: "安全",
                      icon: const Icon(Icons.fingerprint_outlined),
                      cardList: [
                        SettingCard(
                          main: const Text(
                            "启用安全认证",
                            maxLines: 1,
                          ),
                          sub: const Text(
                            "启用密码或生物识别认证",
                            maxLines: 1,
                          ),
                          value: appConfig.useAuthentication,
                          action: (v) {
                            return Switch(
                              value: v,
                              onChanged: (checked) {
                                HapticFeedback.mediumImpact();
                                if (appConfig.appPassword == null && checked) {
                                  Global.showTipsDialog(
                                    context: context,
                                    text: "请先创建应用密码",
                                    onOk: controller.gotoSetPwd,
                                    okText: "去创建",
                                    showCancel: true,
                                  );
                                  appConfig.setUseAuthentication(false);
                                } else {
                                  appConfig.setUseAuthentication(checked);
                                }
                              },
                            );
                          },
                          show: (v) => Platform.isAndroid,
                        ),
                        SettingCard(
                          main: const Text(
                            "更改密码",
                            maxLines: 1,
                          ),
                          sub: Text(
                            "${appConfig.appPassword == null ? '新建' : '更改'}应用密码",
                            maxLines: 1,
                          ),
                          value: appConfig.appPassword,
                          action: (v) {
                            return TextButton(
                              onPressed: () {
                                if (appConfig.appPassword == null) {
                                  controller.gotoSetPwd();
                                } else {
                                  //第一步验证
                                  appConfig.authenticating.value = true;
                                  final homeController =
                                      Get.find<HomeController>();
                                  homeController
                                      .gotoAuthenticationPage("身份验证", false)
                                      ?.then((v) {
                                    //null为正常验证，设置密码，否则主动退出
                                    if (v != null) {
                                      controller.gotoSetPwd();
                                    }
                                  });
                                }
                              },
                              child: Text(
                                  appConfig.appPassword == null ? '新建' : '更改'),
                            );
                          },
                          show: (v) => Platform.isAndroid,
                        ),
                        SettingCard(
                          main: const Text(
                            "密码重新验证",
                            maxLines: 1,
                          ),
                          sub: const Text(
                            "在后台指定时长后重新验证密码",
                            maxLines: 1,
                          ),
                          value: appConfig.appRevalidateDuration,
                          onTap: () {
                            AuthenticationTimeSettingDialog.show(
                              context: context,
                              defaultValue: appConfig.appRevalidateDuration,
                              selected: (v) {
                                return v == appConfig.appRevalidateDuration;
                              },
                              onSelected: (duration) {
                                Future.delayed(
                                  const Duration(milliseconds: 100),
                                ).then(
                                  (value) {
                                    appConfig
                                        .setAppRevalidateDuration(duration);
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            );
                          },
                          action: (v) {
                            var duration = appConfig.appRevalidateDuration;
                            return Text(duration <= 0 ? "立即" : "$duration 分钟");
                          },
                          show: (v) => Platform.isAndroid,
                        ),
                      ],
                    )),

                ///endregion

                ///region 快捷键

                Obx(() => SettingCardGroup(
                      groupName: "热键",
                      icon: const Icon(Icons.keyboard_alt_outlined),
                      cardList: [
                        SettingCard(
                          main: const Text(
                            "历史弹窗",
                            maxLines: 1,
                          ),
                          sub: const Text(
                            "在屏幕任意位置唤起历史记录弹窗",
                            maxLines: 1,
                          ),
                          value: appConfig.historyWindowHotKeys,
                          action: (v) {
                            var keyText = HotKeyEditor.toText(v);
                            return HotKeyEditor(
                              hotKey: keyText,
                              onDone: (modifiers, key, showText, keyCodes) {
                                if (showText == keyText) return;
                                if (modifiers.isEmpty || key == null) {
                                  Global.showTipsDialog(
                                    context: context,
                                    text: "快捷键必须是控制键和非控制键的组合！",
                                  );
                                } else {
                                  Global.showTipsDialog(
                                    context: context,
                                    text: "是否保存快捷键（$showText）设置？",
                                    showCancel: true,
                                    onOk: () {
                                      var hotkey =
                                          AppHotKeyHandler.toSystemHotKey(
                                        keyCodes,
                                      );
                                      AppHotKeyHandler.registerHistoryWindow(
                                        hotkey,
                                      ).then((v) {
                                        //设置为新值
                                        appConfig
                                            .setHistoryWindowHotKeys(keyCodes);
                                      }).catchError((err) {
                                        Global.showTipsDialog(
                                          context: context,
                                          text: "设置失败 $err",
                                        );
                                        //设置为原始值
                                        appConfig.setHistoryWindowHotKeys(
                                          appConfig.historyWindowHotKeys,
                                        );
                                      });
                                    },
                                    onCancel: () {
                                      //设置为原始值
                                      appConfig.setHistoryWindowHotKeys(
                                        appConfig.historyWindowHotKeys,
                                      );
                                    },
                                  );
                                }
                              },
                            );
                          },
                          show: (v) => Platform.isWindows,
                        ),
                        SettingCard(
                          main: const Text(
                            "文件发送",
                            maxLines: 1,
                          ),
                          sub: const Text(
                            "将选定的文件同步到其他设备（桌面无效）",
                            maxLines: 1,
                          ),
                          value: appConfig.syncFileHotKeys,
                          action: (v) {
                            var keyText = HotKeyEditor.toText(v);
                            return HotKeyEditor(
                              hotKey: keyText,
                              onDone: (modifiers, key, showText, keyCodes) {
                                if (showText == keyText) return;
                                if (modifiers.isEmpty || key == null) {
                                  Global.showTipsDialog(
                                    context: context,
                                    text: "快捷键必须是控制键和非控制键的组合！",
                                  );
                                } else {
                                  Global.showTipsDialog(
                                    context: context,
                                    text: "是否保存快捷键（$showText）设置？",
                                    showCancel: true,
                                    onOk: () {
                                      var hotkey =
                                          AppHotKeyHandler.toSystemHotKey(
                                        keyCodes,
                                      );
                                      AppHotKeyHandler.registerFileSync(
                                        hotkey,
                                      ).then((v) {
                                        //设置为新值
                                        appConfig.setSyncFileHotKeys(keyCodes);
                                      }).catchError((err) {
                                        Global.showTipsDialog(
                                          context: context,
                                          text: "设置失败 $err",
                                        );
                                        //设置为原始值
                                        appConfig.setSyncFileHotKeys(
                                          appConfig.syncFileHotKeys,
                                        );
                                      });
                                    },
                                    onCancel: () {
                                      //设置为原始值
                                      appConfig.setSyncFileHotKeys(
                                        appConfig.syncFileHotKeys,
                                      );
                                    },
                                  );
                                }
                              },
                            );
                          },
                          show: (v) => Platform.isWindows,
                        ),
                      ],
                    )),

                ///endregion

                ///region 同步设置

                Obx(() => SettingCardGroup(
                      groupName: "同步",
                      icon: const Icon(Icons.sync_rounded),
                      cardList: [
                        SettingCard(
                          main: const Text(
                            "短信同步",
                            maxLines: 1,
                          ),
                          sub: const Text(
                            "符合规则的短信将自动同步",
                            maxLines: 1,
                          ),
                          value: appConfig.enableSmsSync,
                          show: (v) => Platform.isAndroid,
                          action: (v) {
                            return Switch(
                              value: v,
                              onChanged: (checked) async {
                                if (checked) {
                                  var isGranted = await PermissionHelper
                                      .testAndroidReadSms();
                                  if (isGranted) {
                                    androidChannelService.startSmsListen();
                                  } else {
                                    Global.showTipsDialog(
                                      context: context,
                                      text: "请先授予短信读取权限",
                                      okText: "去授权",
                                      showCancel: true,
                                      onOk: () async {
                                        await PermissionHelper
                                            .reqAndroidReadSms();
                                        if (await PermissionHelper
                                            .testAndroidReadSms()) {
                                          appConfig.setEnableSmsSync(true);
                                          androidChannelService
                                              .startSmsListen();
                                        }
                                      },
                                    );
                                    return;
                                  }
                                } else {
                                  androidChannelService.stopSmsListen();
                                }
                                appConfig.setEnableSmsSync(checked);
                              },
                            );
                          },
                        ),
                        SettingCard(
                          main: const Text(
                            "图片存储至相册中",
                            maxLines: 1,
                          ),
                          sub: const Text(
                            "将保存至 Pictures/${Constants.appName} 中",
                            maxLines: 1,
                          ),
                          value: appConfig.saveToPictures,
                          action: (v) {
                            return Switch(
                              value: v,
                              onChanged: (checked) async {
                                HapticFeedback.mediumImpact();
                                if (checked) {
                                  var path =
                                      "${Constants.androidPicturesPath}/${Constants.appName}";
                                  var res = await PermissionHelper
                                      .testAndroidStoragePerm(path);
                                  if (res) {
                                    appConfig.setSaveToPictures(true);
                                    return;
                                  }
                                  Global.showTipsDialog(
                                    context: context,
                                    text: "无读写权限，需要进行授权",
                                    showCancel: true,
                                    onOk: () async {
                                      Navigator.pop(context);
                                      await PermissionHelper
                                          .reqAndroidStoragePerm(path);
                                      if (!await PermissionHelper
                                          .testAndroidStoragePerm(path)) {
                                        appConfig.setSaveToPictures(false);
                                        Global.showTipsDialog(
                                          context: context,
                                          text: "用户取消授权！",
                                        );
                                      } else {
                                        //授权成功
                                        appConfig.setSaveToPictures(true);
                                      }
                                    },
                                    okText: "去授权",
                                  );
                                } else {
                                  appConfig.setSaveToPictures(false);
                                }
                              },
                            );
                          },
                          show: (v) => Platform.isAndroid,
                        ),
                        SettingCard(
                          main: const Text(
                            "文件存储路径",
                            maxLines: 1,
                          ),
                          sub: Text(
                            appConfig.fileStorePath,
                            maxLines: 1,
                          ),
                          value: false,
                          action: (v) {
                            return TextButton(
                              onPressed: () async {
                                String? directory = await FilePicker.platform
                                    .getDirectoryPath(lockParentWindow: true);
                                if (directory != null) {
                                  appConfig.setFileStorePath(directory);
                                }
                              },
                              child: const Text(
                                "选择",
                                maxLines: 1,
                              ),
                            );
                          },
                          onDoubleTap: () async {
                            await OpenFile.open(
                              appConfig.fileStorePath,
                            );
                          },
                        ),
                      ],
                    )),

                ///endregion

                ///region 规则设置

                SettingCardGroup(
                  groupName: "规则",
                  icon: const Icon(Icons.assignment_outlined),
                  cardList: [
                    SettingCard(
                      main: const Text(
                        "标签规则",
                        maxLines: 1,
                      ),
                      sub: const Text(
                        "符合规则的记录将会自动打上对应标签",
                        maxLines: 1,
                      ),
                      value: false,
                      action: (v) {
                        return TextButton(
                          onPressed: () {
                            var page = TagRuleSettingPage();
                            if (appConfig.isSmallScreen) {
                              Get.to(page);
                            } else {
                              Get.dialog(
                                DynamicSizeWidget(
                                  child: page,
                                ),
                                barrierDismissible: false,
                              );
                            }
                          },
                          child: const Text("配置"),
                        );
                      },
                    ),
                    SettingCard(
                      main: const Text(
                        "短信规则",
                        maxLines: 1,
                      ),
                      sub: const Text(
                        "符合规则的短信将会同步，若未配置则全部同步",
                        maxLines: 1,
                      ),
                      value: false,
                      show: (v) => Platform.isAndroid || true,
                      action: (v) {
                        return TextButton(
                          onPressed: () {
                            var page = SmsRuleSettingPage();
                            if (appConfig.isSmallScreen) {
                              Get.to(page);
                            } else {
                              Get.dialog(
                                DynamicSizeWidget(
                                  child: page,
                                ),
                                barrierDismissible: false,
                              );
                            }
                          },
                          child: const Text("配置"),
                        );
                      },
                    ),
                  ],
                ),

                ///endregion

                ///region 日志

                Obx(
                  () => SettingCardGroup(
                    groupName: "日志",
                    icon: const Icon(Icons.bug_report_outlined),
                    cardList: [
                      SettingCard(
                        main: Row(
                          children: [
                            const Text(
                              "启用日志记录",
                              maxLines: 1,
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Tooltip(
                              message: "打开文件夹",
                              child: GestureDetector(
                                child: const MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Icon(
                                    Icons.open_in_new_outlined,
                                    color: Colors.blueGrey,
                                    size: 17,
                                  ),
                                ),
                                onTap: () async {
                                  Directory(appConfig.logsDirPath).createSync();
                                  try {
                                    var res = await OpenFile.open(
                                      appConfig.logsDirPath,
                                    );
                                    Log.debug(
                                      logTag,
                                      "${res.type.name},${res.message}",
                                    );
                                  } catch (e) {
                                    Log.error(logTag, e);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        sub: Text(
                          "将会占据额外空间，已产生 ${FileUtil.getDirectorySize(appConfig.logsDirPath).sizeStr} 日志",
                          maxLines: 1,
                        ),
                        value: appConfig.enableLogsRecord,
                        onTap: () {
                          if (appConfig.isSmallScreen) {
                            Get.toNamed(Routes.LOG);
                          } else {
                            Get.put(LogController());
                            Get.dialog(
                              DynamicSizeWidget(
                                child: LogPage(),
                              ),
                            ).then((_) => Get.delete<LogController>());
                          }
                        },
                        action: (v) {
                          return Switch(
                            value: v,
                            onChanged: (checked) {
                              HapticFeedback.mediumImpact();
                              appConfig.setEnableLogsRecord(checked);
                              if (!checked) {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text("提示"),
                                      content: const Text("是否删除日志文件？"),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text("取消"),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            FileUtil.deleteDirectoryFiles(
                                              appConfig.logsDirPath,
                                            );
                                            Navigator.pop(context);
                                          },
                                          child: const Text("确定"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                ///endregion

                ///region 统计分析
                SettingCardGroup(
                  groupName: "统计",
                  icon: const Icon(Icons.bar_chart),
                  cardList: [
                    SettingCard(
                      main: const Text(
                        "查看统计",
                        maxLines: 1,
                      ),
                      sub: const Text(
                        "以图表呈现对本地记录的简略统计分析",
                        maxLines: 1,
                      ),
                      value: null,
                      onTap: () {
                        Get.toNamed(Routes.STATISTICS);
                      },
                      action: (v) => IconButton(
                        onPressed: () {
                          Get.toNamed(Routes.STATISTICS);
                        },
                        icon: const Icon(
                          Icons.bar_chart,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                  ],
                ),

                ///endregion

                ///region 关于

                SettingCardGroup(
                  groupName: "关于",
                  icon: const Icon(Icons.info_outline),
                  cardList: [
                    SettingCard(
                      main: const Text(
                        "关于${Constants.appName}",
                        maxLines: 1,
                      ),
                      sub: Text(
                        "${appConfig.version.name}(${appConfig.version.code})",
                        maxLines: 1,
                      ),
                      value: null,
                      action: (v) => IconButton(
                        onPressed: () {
                          Get.dialog(
                            const DynamicSizeWidget(
                              child: UpdateLogPage(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.info_outline,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                  ],
                ),

                ///endregion
                const SizedBox(
                  height: 10,
                ),
              ],
            ),
          ),
          onRefresh: () {
            controller.update();
            return Future.value();
          },
        ),
      ],
    );
  }
}
