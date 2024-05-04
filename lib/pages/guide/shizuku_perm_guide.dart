import 'package:clipshare/components/permission_guide.dart';
import 'package:clipshare/handler/permission_handler.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/pages/guide/base_guide.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/extension.dart';
import 'package:flutter/material.dart';

class ShizukuPermGuide extends BaseGuide {
  var permHandler = ShizukuPermHandler();

  ShizukuPermGuide() {
    super.widget = PermissionGuide(
      title: "Shizuku 权限",
      icon: Icons.copy_all,
      description: "${Constants.appName}基于系统日志监听剪贴板变化\n"
          "Android10 及以上系统需要通过 Shizuku 进行授权\n\n"
          "您的系统版本是 Android${App.osVersion.toInt()}\n",
      grantPerm: null,
      checkPerm: canNext,
      action: (context, hasPerm) {
        return Row(
          mainAxisAlignment: hasPerm
              ? MainAxisAlignment.center
              : MainAxisAlignment.spaceBetween,
          children: [
            hasPerm
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: () {
                      showDialog(
                        context: App.context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Shizuku"),
                            content: const Text(
                              "Shizuku 是一个在 Android 平台上开发的类似于 adb 的工具，它提供了一种更便捷的方式来执行一些需要特殊权限的操作。通过 Shizuku，用户可以在没有 root 权限的情况下执行某些需要特殊权限的命令。\n"
                              "\n下载Shizuku客户端，并通过无线调试或者adb（需要电脑）启动Shizuku然后通过Shizuku对软件进行授权\n"
                              "\nAndroid11及以上版本系统可以在有wifi的情况下直接进行无线调试启动Shizuku",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  "https://shizuku.rikka.app/zh-hans/"
                                      .openUrl();
                                },
                                child: const Text("官网"),
                              ),
                              TextButton(
                                onPressed: () {
                                  "https://shizuku.rikka.app/zh-hans/guide/setup/"
                                      .openUrl();
                                },
                                child: const Text("查看教程"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text("什么是 Shizuku ?"),
                  ),
            hasPerm
                ? const SizedBox.shrink()
                : const SizedBox(
                    width: 30,
                  ),
            TextButton.icon(
              onPressed: () {
                if (!hasPerm) {
                  permHandler.request();
                }
              },
              icon: hasPerm
                  ? const Icon(
                      Icons.check_circle,
                      color: Colors.blue,
                    )
                  : const SizedBox.shrink(),
              label: Text(hasPerm ? "OK" : "去授权"),
            ),
          ],
        );
      },
    );
  }

  @override
  Future<bool> canNext() async {
    return permHandler.hasPermission();
  }
}
