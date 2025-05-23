import 'dart:io';

import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Global {
  Global._private();

  static void toast(String text) {
    final androidChannelService = Get.find<AndroidChannelService>();
    androidChannelService.toast(text);
  }

  static void notify(String content) {
    if (Platform.isAndroid) {
      final androidChannelService = Get.find<AndroidChannelService>();
      androidChannelService.sendNotify(content);
    }
  }

  static void showSnackBar(
    BuildContext? context,
    ScaffoldMessengerState? scaffoldMessengerState,
    String text,
    Color color,
  ) {
    assert(context != null || scaffoldMessengerState != null);
    if (context != null) {
      AnimatedSnackBar(
        builder: ((context) {
          return DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(125),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: MaterialAnimatedSnackBar(
              messageText: text,
              backgroundColor: color,
              type: AnimatedSnackBarType.info,
            ),
          );
        }),
        desktopSnackBarPosition: DesktopSnackBarPosition.topCenter,
        mobileSnackBarPosition: MobileSnackBarPosition.bottom,
        duration: const Duration(seconds: 4),
      ).show(context);
    } else {
      final snackbar = SnackBar(
        content: Text(text),
        backgroundColor: color,
      );
      scaffoldMessengerState!.showSnackBar(snackbar);
    }
  }

  static void showSnackBarSuc({
    BuildContext? context,
    ScaffoldMessengerState? scaffoldMessengerState,
    required String text,
  }) {
    showSnackBar(context, scaffoldMessengerState, text, Colors.blue.shade700);
  }

  static void showSnackBarErr({
    BuildContext? context,
    ScaffoldMessengerState? scaffoldMessengerState,
    required String text,
  }) {
    showSnackBar(context, scaffoldMessengerState, text, Colors.redAccent);
  }

  static void showSnackBarWarn({
    BuildContext? context,
    ScaffoldMessengerState? scaffoldMessengerState,
    required String text,
  }) {
    showSnackBar(context, scaffoldMessengerState, text, Colors.orange);
  }

  static void showTipsDialog({
    required BuildContext context,
    required String text,
    String? title,
    String? okText,
    String? cancelText,
    String? neutralText,
    bool showCancel = false,
    bool showOk = true,
    bool showNeutral = false,
    void Function()? onOk,
    void Function()? onCancel,
    void Function()? onNeutral,
    bool autoDismiss = true,
  }) {
    title = title ?? TranslationKey.tips.tr;
    okText = okText ?? TranslationKey.dialogConfirmText.tr;
    cancelText = cancelText ?? TranslationKey.dialogCancelText.tr;
    neutralText = neutralText ?? TranslationKey.dialogNeutralText.tr;
    showDialog(
      context: context,
      barrierDismissible: autoDismiss,
      builder: (context) {
        return PopScope(
          canPop: autoDismiss,
          child: AlertDialog(
            title: Text(title!),
            content: Text(text),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Visibility(
                    visible: showNeutral,
                    child: TextButton(
                      onPressed: () {
                        if (autoDismiss) {
                          Get.back();
                        }
                        onNeutral?.call();
                      },
                      child: Text(neutralText!),
                    ),
                  ),
                  IntrinsicWidth(
                    child: Row(
                      children: [
                        Visibility(
                          visible: showCancel,
                          child: TextButton(
                            onPressed: () {
                              if (autoDismiss) {
                                Get.back();
                              }
                              onCancel?.call();
                            },
                            child: Text(cancelText!),
                          ),
                        ),
                        Visibility(
                          visible: showOk,
                          child: TextButton(
                            onPressed: () {
                              if (autoDismiss) {
                                Get.back();
                              }
                              onOk?.call();
                            },
                            child: Text(okText!),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  static void showLoadingDialog({
    required BuildContext context,
    bool dismissible = false,
    bool showCancel = false,
    void Function()? onCancel,
    String? loadingText,
  }) {
    showDialog(
      context: context,
      barrierDismissible: dismissible,
      builder: (context) {
        return PopScope(
          canPop: dismissible,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AlertDialog(
                content: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 80,
                        child: Loading(
                          width: 32,
                          description: loadingText != null ? Text(loadingText) : null,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Visibility(
                        visible: showCancel,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                Get.back();
                                onCancel?.call();
                              },
                              child: Text(TranslationKey.dialogCancelText.tr),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
