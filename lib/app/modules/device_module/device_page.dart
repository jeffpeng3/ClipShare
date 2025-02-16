import 'dart:io';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/modules/device_module/device_controller.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/services/socket_service.dart';
import 'package:clipshare/app/widgets/add_device_dialog.dart';
import 'package:clipshare/app/widgets/condition_widget.dart';
import 'package:clipshare/app/widgets/device_card.dart';
import 'package:clipshare/app/widgets/dot.dart';
import 'package:clipshare/app/widgets/loading_dots.dart';
import 'package:clipshare/app/widgets/network_address_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class DevicePage extends GetView<DeviceController> {
  final sktService = Get.find<SocketService>();
  final appConfig = Get.find<ConfigService>();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Column(
          children: <Widget>[
            Obx(
              () => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 12),
                    child: Visibility(
                      visible: controller.pairedList.isNotEmpty,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.devices_rounded),
                              const SizedBox(
                                width: 5,
                              ),
                              Text(
                                TranslationKey.devicePageMyDevicesText.name
                                    .trParams({
                                  'length':
                                      controller.pairedList.length.toString(),
                                }),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: "宋体",
                                ),
                              ),
                            ],
                          ),
                          Obx(
                            () => Offstage(
                              offstage: !appConfig.enableForward,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(right: 5),
                                    child: Dot(
                                      radius: 6.0,
                                      color: controller.forwardConnected.value
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                  ),
                                  Text(TranslationKey
                                      .devicePageForwardServerText.tr),
                                  const SizedBox(width: 10),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ...controller.pairedList,
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                children: [
                  Obx(
                    () => Icon(
                      Icons.online_prediction_rounded,
                      color:
                          controller.discovering.value ? Colors.blueGrey : null,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Obx(
                    () => Text(
                      TranslationKey.devicePageDiscoverDevicesText.trParams({
                        'length': controller.discoverList.length.toString(),
                      }),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: TranslationKey.devicePageRediscoverTooltip.tr,
                    child: Obx(
                      () => RotationTransition(
                        turns: controller.animation.value,
                        child: IconButton(
                          onPressed: () {
                            if (controller.discovering.value) {
                              controller.rotationReverse.value =
                                  !controller.rotationReverse.value;
                              controller.setRotationAnimation();
                              sktService.restartDiscoveryDevices();
                            } else {
                              sktService.startDiscoveryDevices();
                            }
                          },
                          icon: const Icon(
                            Icons.sync,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Tooltip(
                    message: TranslationKey.devicePageManuallyTooltip.tr,
                    child: IconButton(
                      onPressed: () {
                        _showAddDeviceDialog(context);
                      },
                      icon: const Icon(
                        Icons.add,
                        size: 20,
                      ),
                    ),
                  ),
                  Obx(
                    () => Visibility(
                      visible: controller.discovering.value,
                      child: Tooltip(
                        message:
                            TranslationKey.devicePageStopDiscoveringTooltip.tr,
                        child: IconButton(
                          onPressed: () {
                            sktService.stopDiscoveryDevices();
                          },
                          icon: const Icon(
                            Icons.stop,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Obx(() {
                    if (appConfig.deviceDiscoveryStatus.value == null) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 15, left: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          LoadingDots(
                              text:
                                  Text(appConfig.deviceDiscoveryStatus.value!)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            //此处不可以用Visibility组件控制渲染，会导致RoundedClip组件背景色失效
            Obx(
              () => ConditionWidget(
                condition: controller.discoverList.isEmpty,
                visible: DeviceCard(
                  dev: null,
                  isPaired: false,
                  isConnected: false,
                  isSelf: false,
                  minVersion: null,
                  version: null,
                ),
                invisible: Column(
                  children: controller.discoverList,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () async {
                    var interfaces = await NetworkInterface.list();
                    for (var itf in interfaces) {
                      // itf.addresses[0].type
                      print("${itf.name} ${itf.addresses.join(',')}");
                    }
                    showDialog(
                        context: context,
                        builder: (ctx) {
                          return NetworkAddressDialog(
                            interfaces: interfaces,
                          );
                        });
                  },
                  child: Row(
                    children: [
                      Icon(
                        MdiIcons.web,
                        size: 20,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(TranslationKey.showLocalIpAddress.tr),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ],
    );
  }

  //region 页面方法

  ///显示添加设备弹窗
  void _showAddDeviceDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => const AddDeviceDialog(),
    );
  }

//endregion
}
