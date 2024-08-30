import 'package:clipshare/app/routes/app_pages.dart';
import 'package:clipshare/app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(flex: 1, child: Container()),
          Expanded(
            flex: 8,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  "欢迎使用 ${Constants.appName}",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 32, right: 32),
                  child: Text("在使用前我们还需要进行一些必要权限请求以及设置"),
                ),
                TextButton(
                  onPressed: () {
                    Future.delayed(
                      const Duration(milliseconds: 200),
                      () {
                        Get.offNamed(Routes.USER_GUIDE);
                      },
                    );
                  },
                  child: const IntrinsicWidth(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("现在开始"),
                        Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.keyboard_arrow_right,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 1, child: Container()),
        ],
      ),
    );
  }
}
