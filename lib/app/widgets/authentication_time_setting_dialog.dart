import 'package:clipshare/app/widgets/radio_group.dart';
import 'package:flutter/material.dart';

class AuthenticationTimeSettingDialog extends StatelessWidget {
  final void Function(int duration) _onSelected;
  final bool Function(int value) _selected;
  final int _defaultValue;

  const AuthenticationTimeSettingDialog._private({
    super.key,
    required void Function(int) onSelected,
    required bool Function(int) selected,
    required int defaultValue,
  })  : _defaultValue = defaultValue,
        _selected = selected,
        _onSelected = onSelected;

  static void show({
    required BuildContext context,
    required void Function(dynamic duration) onSelected,
    required bool Function(dynamic value) selected,
    required dynamic defaultValue,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("密码重新验证"),
          content: AuthenticationTimeSettingDialog._private(
            onSelected: onSelected,
            selected: selected,
            defaultValue: defaultValue,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("取消"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RadioGroup(
      selected: _selected,
      data: const [
        RadioData(value: 0, label: Text("立即")),
        RadioData(value: 1, label: Text("1 分钟")),
        RadioData(value: 2, label: Text("2 分钟")),
        RadioData(value: 5, label: Text("5 分钟")),
        RadioData(value: 10, label: Text("10 分钟")),
        RadioData(value: 30, label: Text("30 分钟")),
      ],
      defaultValue: _defaultValue,
      onSelected: _onSelected,
    );
  }
}
