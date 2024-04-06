import 'dart:io';

import 'package:clipshare/components/setting_card.dart';
import 'package:clipshare/components/setting_card_group.dart';
import 'package:clipshare/components/text_edit_dialog.dart';
import 'package:clipshare/handler/permission_handler.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/provider/setting_provider.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:refena_flutter/refena_flutter.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> with WidgetsBindingObserver {
  final tag = "ProfilePage";

  //通知权限
  var notifyHandler = NotifyPermHandler();

  //shizuku
  var shizukuHandler = ShizukuPermHandler();

  //悬浮窗权限
  var floatHandler = FloatPermHandler();

  //检查电池优化
  var ignoreBatteryHandler = IgnoreBatteryHandler();
  bool hasNotifyPerm = false;
  bool hasShizukuPerm = false;
  bool hasFloatPerm = false;
  bool hasIgnoreBattery = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      checkPermissions();
    }
  }

  @override
  void initState() {
    super.initState();
    //监听生命周期
    WidgetsBinding.instance.addObserver(this);
    checkPermissions();
  }

  void checkPermissions() {
    if (Platform.isAndroid) {
      notifyHandler.hasPermission().then((v) {
        setState(() {
          hasNotifyPerm = v;
        });
      });
      shizukuHandler.hasPermission().then((v) {
        setState(() {
          hasShizukuPerm = v;
        });
      });
      floatHandler.hasPermission().then((v) {
        setState(() {
          hasFloatPerm = v;
        });
      });
      ignoreBatteryHandler.hasPermission().then((v) {
        setState(() {
          hasIgnoreBattery = v;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder(
      provider: settingProvider,
      builder: (context, vm) {
        final ref = context.ref;
        return Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
          child: ListView(
            children: [
              ///常规
              SettingCardGroup(
                groupName: "常规",
                icon: const Icon(Icons.discount),
                cardList: [
                  SettingCard(
                    main: const Text("开机启动"),
                    value: vm.launchAtStartup,
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
                        ref
                            .notifier(settingProvider)
                            .setLaunchAtStartup(!enabled);
                      },
                    ),
                    show: (v) => Platform.isWindows,
                  ),
                  SettingCard(
                    main: const Text("启动时最小化窗口"),
                    value: vm.startMini,
                    action: (v) => Switch(
                      value: v,
                      onChanged: (checked) {
                        ref.notifier(settingProvider).setStartMini(checked);
                      },
                    ),
                    show: (v) => PlatformExt.isPC,
                  ),
                  SettingCard(
                    main: const Text("显示历史记录悬浮窗"),
                    value: vm.showHistoryFloat,
                    action: (v) => Switch(
                      value: vm.showHistoryFloat,
                      onChanged: (checked) {
                        if (checked) {
                          App.androidChannel
                              .invokeMethod("showHistoryFloatWindow");
                        } else {
                          App.androidChannel
                              .invokeMethod("closeHistoryFloatWindow");
                        }
                        HapticFeedback.mediumImpact();
                        ref
                            .notifier(settingProvider)
                            .setShowHistoryFloat(checked);
                      },
                    ),
                    show: (v) => Platform.isAndroid,
                  ),
                  SettingCard(
                    main: const Text("记住上次窗口大小"),
                    sub: Text(
                      "${vm.rememberWindowSize ? "记录值：${vm.windowSize}，" : ""}默认值：${Constants.defaultWindowSize}",
                    ),
                    value: vm.rememberWindowSize,
                    action: (v) => Switch(
                      value: v,
                      onChanged: (checked) {
                        HapticFeedback.mediumImpact();
                        ref
                            .notifier(settingProvider)
                            .setRememberWindowSize(checked);
                      },
                    ),
                    show: (v) => PlatformExt.isPC,
                  ),
                ],
              ),

              ///权限
              SettingCardGroup(
                groupName: "权限",
                icon: const Icon(Icons.admin_panel_settings),
                cardList: [
                  SettingCard(
                    main: const Text("通知权限"),
                    sub: const Text("用于启动前台服务"),
                    value: hasNotifyPerm,
                    action: (val) => Icon(
                      val ? Icons.check_circle : Icons.help,
                      color: val ? Colors.green : Colors.orange,
                    ),
                    show: (v) => Platform.isAndroid && !v,
                    onTap: () {
                      if (!hasNotifyPerm) {
                        notifyHandler.request();
                      }
                    },
                  ),
                  SettingCard(
                    main: const Text("悬浮窗权限"),
                    sub: const Text("高版本系统中通过悬浮窗获取剪贴板焦点"),
                    value: hasFloatPerm,
                    action: (val) => Icon(
                      val ? Icons.check_circle : Icons.help,
                      color: val ? Colors.green : Colors.orange,
                    ),
                    show: (v) => Platform.isAndroid && !v,
                    onTap: () {
                      if (!hasFloatPerm) {
                        floatHandler.request();
                      }
                    },
                  ),
                  SettingCard(
                    main: const Text("剪贴板权限"),
                    sub: const Text("请通过Shizuku或Root授权"),
                    value: hasShizukuPerm,
                    action: (val) => Icon(
                      val ? Icons.check_circle : Icons.help,
                      color: val ? Colors.green : Colors.orange,
                    ),
                    show: (v) => Platform.isAndroid && !v,
                    onTap: () {
                      if (!hasShizukuPerm) {
                        shizukuHandler.request();
                      }
                    },
                  ),
                  SettingCard(
                    main: const Text("电池优化"),
                    sub: const Text("添加电池优化防止被后台系统杀死"),
                    value: hasIgnoreBattery,
                    action: (val) => Icon(
                      val ? Icons.check_circle : Icons.help,
                      color: val ? Colors.green : Colors.orange,
                    ),
                    show: (v) => Platform.isAndroid && !v,
                    onTap: () {
                      if (!hasIgnoreBattery) {
                        ignoreBatteryHandler.request();
                      }
                    },
                  ),
                ],
              ),

              ///发现
              SettingCardGroup(
                groupName: "发现",
                icon: const Icon(Icons.wifi),
                cardList: [
                  SettingCard(
                    main: const Text("设备名称"),
                    sub: const Text("其他人显示的设备名称"),
                    value: vm.localName,
                    action: (v) => Text(v),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => TextEditDialog(
                          title: "修改设备名称",
                          labelText: "设备名称",
                          initStr: vm.localName,
                          onOk: (str) {
                            ref.notifier(settingProvider).setLocalName(str);
                          },
                        ),
                      );
                    },
                  ),
                  SettingCard(
                    main: const Text("端口号"),
                    sub: const Text(
                      "默认值 ${Constants.port}。修改后可能无法被自动发现",
                    ),
                    value: vm.port,
                    action: (v) => Text(v.toString()),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => TextEditDialog(
                          title: "修改端口",
                          labelText: "端口",
                          initStr: vm.port.toString(),
                          verify: (str) {
                            var port = int.tryParse(str);
                            if (port == null) return false;
                            return port >= 0 && port <= 65535;
                          },
                          errorText: "端口号范围0-65535",
                          onOk: (str) {
                            ref.notifier(settingProvider).setPort(str.toInt());
                          },
                        ),
                      );
                    },
                  ),
                  SettingCard(
                    main: const Text("可被发现"),
                    sub: const Text(
                      "可以被其它设备自动发现",
                    ),
                    value: vm.allowDiscover,
                    action: (v) => Switch(
                      value: v,
                      onChanged: (checked) {
                        HapticFeedback.mediumImpact();
                        ref.notifier(settingProvider).setAllowDiscover(checked);
                      },
                    ),
                  ),
                ],
              ),

              ///关于
              SettingCardGroup(
                groupName: "关于",
                icon: const Icon(Icons.info),
                cardList: [
                  SettingCard(
                    main: const Text("关于${Constants.appName}"),
                    sub: Text(App.version.name),
                    value: false,
                    action: (v) => TextButton(
                      onPressed: () {},
                      child: const Text("检测更新"),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
        );
      },
    );
  }
}
