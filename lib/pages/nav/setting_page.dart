import 'dart:convert';
import 'dart:io';

import 'package:clipshare/components/hot_key_editor.dart';
import 'package:clipshare/components/regular_setting_add_dialog.dart';
import 'package:clipshare/components/settings/card/setting_card.dart';
import 'package:clipshare/components/settings/card/setting_card_group.dart';
import 'package:clipshare/components/settings/text_edit_dialog.dart';
import 'package:clipshare/handler/hot_key_handler.dart';
import 'package:clipshare/handler/permission_handler.dart';
import 'package:clipshare/listeners/socket_listener.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/pages/settings/regular_setting_page.dart';
import 'package:clipshare/pages/update_log_page.dart';
import 'package:clipshare/provider/setting_provider.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/extension.dart';
import 'package:clipshare/util/file_util.dart';
import 'package:clipshare/util/global.dart';
import 'package:clipshare/util/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:open_file_plus/open_file_plus.dart';
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
    return Stack(
      children: [
        ListView(),
        RefreshIndicator(
          child: ViewModelBuilder(
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
                      icon: const Icon(Icons.discount_outlined),
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
                              ref
                                  .notifier(settingProvider)
                                  .setStartMini(checked);
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
                          main: const Text("锁定悬浮窗位置"),
                          value: vm.lockHistoryFloatLoc,
                          action: (v) => Switch(
                            value: vm.lockHistoryFloatLoc,
                            onChanged: (checked) {
                              HapticFeedback.mediumImpact();
                              App.androidChannel.invokeMethod(
                                "lockHistoryFloatLoc",
                                {"loc": checked},
                              );
                              ref
                                  .notifier(settingProvider)
                                  .setLockHistoryFloatLoc(checked);
                            },
                          ),
                          show: (v) =>
                              Platform.isAndroid && vm.showHistoryFloat,
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
                                  ref
                                      .notifier(settingProvider)
                                      .setLocalName(str);
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
                                  ref
                                      .notifier(settingProvider)
                                      .setPort(str.toInt());
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
                              ref
                                  .notifier(settingProvider)
                                  .setAllowDiscover(checked);
                            },
                          ),
                        ),
                        SettingCard(
                          main: Row(
                            children: [
                              const Text("心跳检测间隔"),
                              const SizedBox(
                                width: 5,
                              ),
                              Tooltip(
                                message: "说明",
                                child: GestureDetector(
                                  child: const MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Icon(
                                      Icons.question_mark_outlined,
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
                          ),
                          value: vm.heartbeatInterval,
                          action: (v) => Text(v <= 0 ? '不检测' : '${v}s'),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => TextEditDialog(
                                title: "心跳间隔",
                                labelText: "心跳间隔",
                                initStr:
                                    "${vm.heartbeatInterval <= 0 ? '' : vm.heartbeatInterval}",
                                verify: (str) {
                                  var port = int.tryParse(str);
                                  if (port == null) return false;
                                  return true;
                                },
                                errorText: "单位秒，0为禁用检测",
                                onOk: (str) async {
                                  await ref
                                      .notifier(settingProvider)
                                      .setHeartbeatInterval(str);
                                  var enable = str.toInt() > 0;
                                  Log.debug(tag, "${enable ? '启用' : '禁用'}心跳检测");
                                  if (enable) {
                                    SocketListener.inst.startHeartbeatTest();
                                  } else {
                                    SocketListener.inst.stopHeartbeatTest();
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    ///快捷键
                    SettingCardGroup(
                      groupName: "快捷键",
                      icon: const Icon(Icons.keyboard_alt_outlined),
                      cardList: [
                        SettingCard(
                          main: const Text("历史弹窗"),
                          sub: const Text("在屏幕任意位置唤起历史记录弹窗"),
                          value: vm.historyWindowHotKeys,
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
                                        ref
                                            .notifier(settingProvider)
                                            .setHistoryWindowHotKeys(keyCodes);
                                      }).catchError((err) {
                                        Global.showTipsDialog(
                                          context: context,
                                          text: "设置失败 $err",
                                        );
                                        //设置为原始值
                                        ref
                                            .notifier(settingProvider)
                                            .setHistoryWindowHotKeys(
                                              vm.historyWindowHotKeys,
                                            );
                                      });
                                    },
                                    onCancel: () {
                                      //设置为原始值
                                      ref
                                          .notifier(settingProvider)
                                          .setHistoryWindowHotKeys(
                                            vm.historyWindowHotKeys,
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
                    ),

                    ///同步设置
                    SettingCardGroup(
                      groupName: "同步",
                      icon: const Icon(Icons.sync_rounded),
                      cardList: [
                        SettingCard(
                          main: const Text("短信同步"),
                          sub: const Text("符合规则的短信将自动同步"),
                          value: false,
                          show: (v) => PlatformExt.isMobile,
                          action: (v) {
                            return Switch(value: v, onChanged: (checked) {});
                          },
                        ),
                        SettingCard(
                          main: const Text("文件同步"),
                          sub: const Text("符合规则的文件将允许同步"),
                          value: false,
                          show: (v) => PlatformExt.isPC,
                          action: (v) {
                            return Switch(value: v, onChanged: (checked) {});
                          },
                        ),
                        SettingCard(
                          main: const Text("文件存储路径"),
                          sub: const Text("/data/..."),
                          value: false,
                          action: (v) {
                            return TextButton(
                              onPressed: true ? null : () {},
                              child: const Text("选择"),
                            );
                          },
                        ),
                      ],
                    ),

                    ///规则设置
                    SettingCardGroup(
                      groupName: "规则",
                      icon: const Icon(Icons.assignment_outlined),
                      cardList: [
                        SettingCard(
                          main: const Text("标签规则"),
                          sub: const Text("符合规则的记录将会自动打上对应标签"),
                          value: false,
                          action: (v) {
                            return TextButton(
                              onPressed: () {
                                var page = RegularSettingPage(
                                  initData: jsonDecode(
                                    App.settings.tagRegulars,
                                  )["data"],
                                  onAdd: (data, remove) {
                                    var tag = data["name"] as String?;
                                    var regular = data["regular"] as String?;
                                    if (tag.isNullOrEmpty ||
                                        regular.isNullOrEmpty) {
                                      Global.showTipsDialog(
                                        context: context,
                                        text: "请输入完整！",
                                      );
                                      return null;
                                    }
                                    var key = UniqueKey();
                                    return SettingCard(
                                      key: key,
                                      main: Text("标签：$tag"),
                                      sub: Text("规则：$regular"),
                                      value: data,
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(8.0),
                                      ),
                                      action: (data) {
                                        return IconButton(
                                          onPressed: () {
                                            remove(key);
                                          },
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  renderEditLayout: (onChange) {
                                    return RegularSettingAddDialog(
                                      onChange: onChange,
                                    );
                                  },
                                  confirm: (res) {
                                    var oldValue = jsonDecode(
                                      App.settings.tagRegulars,
                                    );
                                    var version = oldValue["version"];
                                    var json = jsonEncode(
                                      {
                                        "version": version + 1,
                                        "data": res,
                                      },
                                    );
                                    ref
                                        .notifier(settingProvider)
                                        .setTagRegulars(json);
                                  },
                                  title: "标签规则配置",
                                );
                                if (App.isSmallScreen) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => page,
                                    ),
                                  );
                                } else {
                                  Global.showDialogPage(
                                    context: context,
                                    child: page,
                                    dismissible: false,
                                  );
                                }
                              },
                              child: const Text("配置"),
                            );
                          },
                        ),
                        SettingCard(
                          main: const Text("文件规则"),
                          sub: const Text("符合指定文件扩展或大小的文件将会允许同步"),
                          value: false,
                          show: (v) => PlatformExt.isPC,
                          action: (v) {
                            return TextButton(
                              onPressed: true ? null : () {},
                              child: const Text("配置"),
                            );
                          },
                        ),
                        SettingCard(
                          main: const Text("短信规则"),
                          sub: const Text("符合规则的短信将会同步"),
                          value: false,
                          show: (v) => PlatformExt.isMobile,
                          action: (v) {
                            return TextButton(
                              onPressed: true ? null : () {},
                              child: const Text("配置"),
                            );
                          },
                        ),
                      ],
                    ),

                    ///日志
                    SettingCardGroup(
                      groupName: "日志",
                      icon: const Icon(Icons.bug_report_outlined),
                      cardList: [
                        SettingCard(
                          main: Row(
                            children: [
                              const Text("启用日志记录"),
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
                                      size: 20,
                                    ),
                                  ),
                                  onTap: () async {
                                    // late OpenResult res;
                                    try {
                                      var res =
                                          await OpenFile.open(App.logsDirPath);
                                      Log.debug(
                                        tag,
                                        "${res.type.name},${res.message}",
                                      );
                                    } catch (e) {
                                      Log.error(tag, e);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          sub: Text(
                            "将会占据额外空间，已产生 ${FileUtil.getDirectorySize(App.logsDirPath).sizeStr} 日志",
                          ),
                          value: vm.enableLogsRecord,
                          action: (v) {
                            return Switch(
                              value: v,
                              onChanged: (checked) {
                                HapticFeedback.mediumImpact();
                                ref
                                    .notifier(settingProvider)
                                    .setEnableLogsRecord(checked);
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
                                                App.logsDirPath,
                                              );
                                              Navigator.pop(context);
                                              setState(() {});
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

                    ///关于
                    SettingCardGroup(
                      groupName: "关于",
                      icon: const Icon(Icons.info_outline),
                      cardList: [
                        SettingCard(
                          main: const Text("关于${Constants.appName}"),
                          sub: Text(App.version.name),
                          value: false,
                          action: (v) => IconButton(
                            onPressed: () {
                              Global.showDialogPage(
                                context: context,
                                child: const UpdateLogPage(),
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
                    const SizedBox(
                      height: 10,
                    ),
                  ],
                ),
              );
            },
          ),
          onRefresh: () {
            setState(() {});
            return Future.value();
          },
        ),
      ],
    );
  }
}
