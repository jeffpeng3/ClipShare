import 'dart:io';

import 'package:clipshare/app/modules/home_module/home_controller.dart';
import 'package:clipshare/app/services/channels/android_channel.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/crypto.dart';
import 'package:clipshare/app/utils/log.dart';
import 'package:clipshare/app/widgets/auth_password_input.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

class AuthenticationPage extends StatefulWidget {
  final bool lock;
  final String localizedReason;

  const AuthenticationPage(
      {super.key, this.lock = true, required this.localizedReason});

  @override
  State<StatefulWidget> createState() {
    return _AuthenticationState();
  }
}

class _AuthenticationState extends State<AuthenticationPage> {
  final _auth = LocalAuthentication();
  var _supportAuth = false;
  var _authenticating = false;
  final tag = "AuthenticationPage";
  var _backPage = false;
  final appConfig = Get.find<ConfigService>();
  final homeController = Get.find<HomeController>();
  final androidChannelService = Get.find<AndroidChannelService>();

  @override
  void initState() {
    super.initState();
    _backPage = !widget.lock;
    _auth.isDeviceSupported().then((supported) {
      _supportAuth = supported;
      if (!_supportAuth) {
        return;
      }
      showBottomSheetAuthentication();
    });
  }

  void showBottomSheetAuthentication() {
    showModalBottomSheet(
      // isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      context: context,
      showDragHandle: true,
      isDismissible: false,
      elevation: 100,
      builder: (BuildContext context) {
        authenticate();
        return Container(
          constraints: const BoxConstraints(minWidth: 500),
          padding: const EdgeInsets.only(bottom: 30, top: 10),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const Text(
                  "身份验证",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: TextButton(
                    child: const Text(
                      "使用密码",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    onPressed: () {
                      Future.delayed(const Duration(milliseconds: 100), () {
                        Navigator.pop(context);
                      });
                    },
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.fingerprint_outlined,
                      color: Colors.blueAccent,
                      size: 100,
                    ),
                    TextButton(
                      onPressed: authenticate,
                      child: const Text("开始验证"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _backPage,
      onPopInvoked: _backPage
          ? null
          : (bool didPop) {
              if (Platform.isAndroid && appConfig.authenticating.value) {
                androidChannelService.moveToBg();
              }
            },
      child: Scaffold(
        body: AuthPasswordInput(
          onFinished: (String input, String? second) {
            return CryptoUtil.toMD5(input) == appConfig.appPassword;
          },
          onOk: (input) {
            _onAuthenticated();
            return false;
          },
        ),
      ),
    );
  }

  Future<bool> checkAuth() async {
    if (_supportAuth && !_authenticating) {
      _authenticating = true;
      var authenticated = await _auth.authenticate(
        authMessages: [
          const AndroidAuthMessages(
            biometricHint: "",
            signInTitle: "需要身份验证",
          ),
        ],
        localizedReason: widget.localizedReason,
      );
      _authenticating = false;
      Log.debug(tag, "authenticated $authenticated");
      return authenticated;
    }
    return false;
  }

  void _onAuthenticated([bool useSystem = false]) {
    appConfig.authenticating.value = false;
    setState(() {
      _backPage = true;
      homeController.pausedTime = null;
      //正常验证，添加返回值
      Navigator.of(context).pop(true);
      if (useSystem) {
        Navigator.of(context).pop(true);
      }
    });
  }

  Future<void> authenticate() async {
    checkAuth().then((authenticated) {
      if (authenticated) {
        _onAuthenticated(true);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}
