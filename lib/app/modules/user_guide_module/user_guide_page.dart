import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/modules/user_guide_module/user_guide_controller.dart';
import 'package:clipshare/app/widgets/condition_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class UserGuidePage extends GetView<UserGuideController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => ConditionWidget(
          visible: controller.isInitFinished.value,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Obx(
                      () => TextButton(
                        onPressed: controller
                                .guides[controller.current.value].allowSkip
                            ? () async {
                                if (controller.current.value ==
                                    controller.guides.length - 1) {
                                  //跳转到首页
                                  controller.gotoHomePage();
                                } else {
                                  controller.gotoNext();
                                }
                              }
                            : null,
                        child: Text(
                          controller.guides[controller.current.value]
                                      .allowSkip &&
                                  !controller.canNextGuide.value
                              ? TranslationKey.skipGuide.tr
                              : "",
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: PageView(
                    controller: controller.pageController,
                    pageSnapping: true,
                    onPageChanged: (idx) async {
                      if (idx > controller.current.value &&
                          !controller.canNextGuide.value) {
                        controller.pageController.previousPage(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.ease,
                        );
                        return;
                      }
                      controller.current.value = idx;
                      await controller.updateCanNext();
                    },
                    children: [
                      for (var idx = 0; idx < controller.guides.length; idx++)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [controller.guides[idx].widget],
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Obx(
                      () => TextButton(
                        onPressed: controller.current.value == 0
                            ? null
                            : controller.gotoPre,
                        child: Text(TranslationKey.previousGuide.tr),
                      ),
                    ),
                    Expanded(
                      child: Obx(
                        () => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < controller.guides.length; i++)
                              AnimatedContainer(
                                width:
                                    i == controller.current.value ? 36.0 : 16.0,
                                height: 16.0,
                                duration: const Duration(milliseconds: 200),
                                child: Center(
                                  child: AnimatedContainer(
                                    width: i == controller.current.value
                                        ? 30.0
                                        : 10.0,
                                    height: 10.0,
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color: i <= controller.current.value
                                          ? Colors.blue
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 70,
                      child: Obx(
                        () => TextButton(
                          onPressed: controller.canNextGuide.value
                              ? () async {
                                  if (controller.current.value ==
                                      controller.guides.length - 1) {
                                    controller.gotoHomePage();
                                  } else {
                                    controller.gotoNext();
                                  }
                                }
                              : null,
                          child: Obx(
                            () => Text(
                              controller.current.value ==
                                      controller.guides.length - 1
                                  ? TranslationKey.finishGuide.tr
                                  : TranslationKey.nextGuide.tr,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          replacement: const Center(
            child: SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
