import 'dart:io';

import 'package:clipshare/components/auth_password_input.dart';
import 'package:clipshare/listeners/screen_opened_listener.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/util/log.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:local_auth/local_auth.dart';

class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AuthenticationState();
  }
}

class _AuthenticationState extends State<AuthenticationPage>
    implements ScreenOpenedObserver {
  final _auth = LocalAuthentication();
  var _supportAuth = false;
  var _authenticating = false;
  final tag = "AuthenticationPage";
  var _backPage = false;

  @override
  void initState() {
    super.initState();
    App.authenticating = true;
    ScreenOpenedListener.inst.register(this);
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
                    )),
                GestureDetector(
                  onTap: onOpened,
                  child: const Icon(
                    Icons.fingerprint_outlined,
                    color: Colors.blueAccent,
                    size: 100,
                  ),
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
              if (Platform.isAndroid && App.authenticating) {
                App.androidChannel.invokeMethod("moveToBg");
              }
            },
      child: Scaffold(
        body: AuthPasswordInput(
          again: true,
          errorText: "两次密码不一致！",
          onFinished: (String input, String? second) {
            return input == second;
          },
          onOk: () {
            _onAuthenticated();
          },
        ),
      ),
    );
  }

  Future<bool> checkAuth() async {
    if (_supportAuth && !_authenticating) {
      _authenticating = true;
      var authenticated = await _auth.authenticate(
        localizedReason: 'Let OS determine authentication method',
      );
      _authenticating = false;
      Log.debug(tag, "authenticated $authenticated");
      return authenticated;
    }
    return false;
  }

  void _onAuthenticated([bool useSystem = false]) {
    App.authenticating = false;
    setState(() {
      _backPage = true;
      Navigator.pop(context);
      if (useSystem) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Future<void> onOpened() async {
    checkAuth().then((authenticated) {
      if (authenticated) {
        _onAuthenticated(true);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    ScreenOpenedListener.inst.remove(this);
  }
}
