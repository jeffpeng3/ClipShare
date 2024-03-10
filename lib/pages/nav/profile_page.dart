import 'package:clipshare/components/setting_card.dart';
import 'package:clipshare/components/setting_header.dart';
import 'package:clipshare/components/text_edit_dialog.dart';
import 'package:clipshare/provider/setting_provider.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/platform_util.dart';
import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final tag = "ProfilePage";
  static const double radius = 8.0;
  final topBorder = const BorderRadius.only(
    topLeft: Radius.circular(radius),
    topRight: Radius.circular(radius),
  );
  final bottomBorder = const BorderRadius.only(
    bottomLeft: Radius.circular(radius),
    bottomRight: Radius.circular(radius),
  );
  final allBorder = const BorderRadius.all(Radius.circular(radius));

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder(
      provider: settingProvider,
      builder: (context, vm) {
        final ref = context.ref;
        return Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingHeader(title: "常规", icon: Icon(Icons.discount)),
              SettingCard(
                main: const Text("开机启动"),
                value: vm.launchAtStartup,
                action: (v) => Switch(
                  value: v,
                  onChanged: (checked) {
                    ref.notifier(settingProvider).setLaunchAtStartup(checked);
                  },
                ),
                separate: true,
                borderRadius: topBorder,
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
                borderRadius: bottomBorder,
                show: () => PlatformUtil.isPC(),
              ),
              const SettingHeader(title: "发现", icon: Icon(Icons.wifi)),
              SettingCard(
                main: const Text("设备名称"),
                sub: const Text("其他人显示的设备名称"),
                value: vm.localName,
                action: (v) => Text(v),
                separate: true,
                borderRadius: topBorder,
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
                separate: true,
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
                borderRadius: bottomBorder,
              ),
            ],
          ),
        );
      },
    );
  }
}
