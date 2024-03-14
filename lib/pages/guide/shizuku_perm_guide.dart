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
    super.widget = Column(
      children: [
        const PermissionGuide(
          title: "剪贴板权限",
          icon: Icons.copy_all,
          description: "${Constants.appName}基于系统日志监听剪贴板变化\n需要通过 Shizuku 进行授权",
          grantPerm: null,
        ),
        const SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
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
                            "https://shizuku.rikka.app/zh-hans/".openUrl();
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
            const SizedBox(
              width: 30,
            ),
            TextButton(
              onPressed: permHandler.request,
              child: const Text("去授权"),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Future<bool> canNext() async {
    return permHandler.hasPermission();
  }
}
