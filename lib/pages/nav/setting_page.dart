import 'dart:io';

import 'package:clipshare/components/setting_card.dart';
import 'package:clipshare/components/setting_card_group.dart';
import 'package:clipshare/components/text_edit_dialog.dart';
import 'package:clipshare/provider/setting_provider.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/platform_util.dart';
import 'package:flutter/material.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:refena_flutter/refena_flutter.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final tag = "ProfilePage";

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
                        ref
                            .notifier(settingProvider)
                            .setLaunchAtStartup(checked);
                        PackageInfo packageInfo =
                            await PackageInfo.fromPlatform();
                        launchAtStartup.setup(
                          appName: packageInfo.appName,
                          appPath: Platform.resolvedExecutable,
                        );
                        if (checked) {
                          await launchAtStartup.enable();
                        } else {
                          await launchAtStartup.disable();
                        }
                      },
                    ),
                    show: () => PlatformUtil.isPC(),
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
                    show: () => PlatformUtil.isPC(),
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
                    sub: const Text("进行相关系统通知"),
                    value: true,
                    action: (val) => Icon(
                      val ? Icons.check_circle : Icons.help,
                      color: val ? Colors.green : Colors.orange,
                    ),
                  ),
                  SettingCard(
                    main: const Text("悬浮窗权限"),
                    sub: const Text("高版本系统中通过悬浮窗获取剪贴板焦点"),
                    value: true,
                    action: (val) => Icon(
                      val ? Icons.check_circle : Icons.help,
                      color: val ? Colors.green : Colors.orange,
                    ),
                  ),
                  SettingCard(
                    main: const Text("剪贴板权限"),
                    sub: const Text("请通过Shizuku或Root授权"),
                    value: true,
                    action: (val) => Icon(
                      val ? Icons.check_circle : Icons.help,
                      color: val ? Colors.green : Colors.orange,
                    ),
                  ),
                  SettingCard(
                    main: const Text("电池优化"),
                    sub: const Text("添加电池优化防止被后台系统杀死"),
                    value: false,
                    action: (val) => Icon(
                      val ? Icons.check_circle : Icons.help,
                      color: val ? Colors.green : Colors.orange,
                    ),
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
                            ref.notifier(settingProvider).setLocalName(str);
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
                    main: const Text("开源相关"),
                    value: false,
                    action: (v) => const Icon(Icons.code),
                  ),
                  SettingCard(
                    main: const Text("关于软件"),
                    sub: const Text("V1.0"),
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
              )
            ],
          ),
        );
      },
    );
  }
}
