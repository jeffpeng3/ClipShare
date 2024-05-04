import 'package:clipshare/listeners/screen_opened_listener.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/util/log.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    print("1123123");
    App.authenticating = true;
    ScreenOpenedListener.inst.register(this);
    _auth.isDeviceSupported().then((supported) => _supportAuth = supported);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "身份验证",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
              ),
              SizedBox(
                height: 20,
              ),
              GestureDetector(
                child: Icon(
                  Icons.fingerprint_outlined,
                  color: Colors.blueAccent,
                  size: 100,
                ),
                onTap: onOpened,
              ),
            ],
          ),
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

  @override
  Future<void> onOpened() async {
    checkAuth().then((authenticated) {
      if (authenticated) {
        App.authenticating = false;
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    ScreenOpenedListener.inst.remove(this);
  }
}
