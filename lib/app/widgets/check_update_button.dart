import 'package:clipshare/app/utils/app_update_info_util.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:flutter/material.dart';

class CheckUpdateButton extends StatefulWidget {
  const CheckUpdateButton({super.key});

  @override
  State<StatefulWidget> createState() => _CheckUpdateButtonState();
}

class _CheckUpdateButtonState extends State<CheckUpdateButton> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        setState(() {
          loading = true;
        });
        AppUpdateInfoUtil.showUpdateInfo().then((hasNewest) {
          if (!hasNewest) {
            Global.showSnackBarSuc(context: context, text: "已是最新版本");
          }
        }).catchError((err) {
          Global.showTipsDialog(
            context: context,
            text: err.toString(),
          );
        }).whenComplete(() {
          setState(() {
            loading = false;
          });
        });
      },
      child: Visibility(
        replacement: const Text("检查更新"),
        visible: loading,
        child: const CircularProgressIndicator(
          strokeWidth: 2.0,
        ),
      ),
    );
  }
}
