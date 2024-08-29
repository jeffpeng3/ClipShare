import 'dart:io';

import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RoundedScaffold extends StatelessWidget {
  final Widget title;
  final Icon icon;
  final Widget child;
  final Widget? floatingActionButton;

  const RoundedScaffold({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final appConfig = Get.find<ConfigService>();
    bool isSmallScreen =
        MediaQuery.of(context).size.width <= Constants.smallScreenWidth;
    return Scaffold(
      //半透明解决弹窗圆角问题
      backgroundColor: isSmallScreen ? appConfig.bgColor : Colors.transparent,
      appBar: isSmallScreen
          ? AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: title,
            )
          : null,
      body: Column(
        children: [
          Visibility(
            visible: !isSmallScreen,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                child: Row(
                  children: [
                    icon,
                    const SizedBox(
                      width: 5,
                    ),
                    Expanded(
                      child: DefaultTextStyle(
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontFamily:
                              Platform.isWindows ? 'Microsoft YaHei' : null,
                        ),
                        child: title,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                color: appConfig.bgColor,
              ),
              child: child,
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
