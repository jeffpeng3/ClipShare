import 'package:flutter/cupertino.dart';

class ConditionWidget extends StatelessWidget {
  final Widget visible;
  final Widget? invisible;
  final bool condition;

  const ConditionWidget({
    super.key,
    required this.condition,
    required this.visible,
    this.invisible,
  });

  @override
  Widget build(BuildContext context) {
    return condition ? visible : invisible ?? const SizedBox.shrink();
  }
}
