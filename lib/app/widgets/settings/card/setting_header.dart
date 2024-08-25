import 'package:flutter/material.dart';

class SettingHeader<T> extends StatelessWidget {
  final String title;
  final Icon icon;

  const SettingHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: IntrinsicHeight(
        child: Row(
          children: [
            icon,
            const SizedBox(
              width: 5,
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}
