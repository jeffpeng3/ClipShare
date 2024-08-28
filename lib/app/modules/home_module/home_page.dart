import 'dart:io';

import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/widgets/condition_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class HomePage extends GetView<HomeController> {
  final appConfig = Get.find<ConfigService>();
  final androidChannelService = Get.find<AndroidChannelService>();

  @override
  Widget build(BuildContext context) {
    controller.screenWidth = MediaQuery.of(context).size.width;
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (Platform.isAndroid) {
          androidChannelService.moveToBg();
        }
      },
      child: Scaffold(
        backgroundColor: appConfig.bgColor,
        appBar: !controller.showLeftBar
            ? AppBar(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                title: Row(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Obx(
                            () => ConditionWidget(
                              condition: appConfig.isMultiSelectionMode.value,
                              visible: const Icon(Icons.checklist),
                              invisible:
                                  controller.navBarItems[controller.index].icon,
                            ),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Obx(
                            () {
                              final selectionMode =
                                  appConfig.isMultiSelectionMode.value;
                              final pageTitle = controller
                                  .navBarItems[controller.index].label!;
                              final selectionText =
                                  appConfig.multiSelectionText.value;
                              return Text(
                                selectionMode ? selectionText : pageTitle,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Obx(
                      () => Visibility(
                        visible: !appConfig.isMultiSelectionMode.value,
                        child: IconButton(
                          onPressed: () {
                            //导航至搜索页面
                            controller.gotoSearchPage(null, null);
                          },
                          tooltip: "搜索",
                          icon: const Icon(
                            Icons.search_rounded,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                automaticallyImplyLeading: false,
              )
            : null,
        body: Row(
          children: [
            controller.showLeftBar
                ? Obx(
                    () => NavigationRail(
                      leading: controller.leftMenuExtend.value
                          ? Row(
                              children: [
                                controller.logoImg,
                                const SizedBox(
                                  width: 10,
                                ),
                                const Text(Constants.appName),
                              ],
                            )
                          : controller.logoImg,
                      extended: controller.leftMenuExtend.value,
                      onDestinationSelected: (i) {
                        controller.index = i;
                      },
                      minExtendedWidth: 200,
                      destinations: controller.leftBarItems,
                      selectedIndex: controller.index,
                      trailing: Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: IconButton(
                              icon: Icon(
                                controller.leftMenuExtend.value
                                    ? Icons.keyboard_double_arrow_left_outlined
                                    : Icons
                                        .keyboard_double_arrow_right_outlined,
                                color: Colors.blueGrey,
                              ),
                              onPressed: () {
                                controller.leftMenuExtend.value =
                                    !controller.leftMenuExtend.value;
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            Expanded(
              child: Obx(
                () => IndexedStack(
                  index: controller.index,
                  children: controller.pages,
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: !controller.showLeftBar
            ? Obx(
                () => BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  currentIndex: controller.index,
                  onTap: (i) => controller.index = i,
                  items: controller.navBarItems,
                ),
              )
            : null,
      ),
    );
  }
}
