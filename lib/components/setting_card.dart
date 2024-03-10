import 'package:flutter/material.dart';

class Setting<T> extends StatefulWidget {
  final String name;
  final T value;
  final T defVal;
  final Widget main;
  final Widget? sub;
  final Widget Function(T val)? action;
  final bool separate;
  final void Function()? onTap;

  const Setting({
    super.key,
    required this.name,
    required this.main,
    required this.defVal,
    this.sub,
    this.action,
    this.separate = false,
    this.onTap,
  }) : value = defVal;

  @override
  State<StatefulWidget> createState() {
    return _SettingState<T>();
  }
}

class _SettingState<T> extends State<Setting<T>> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          widget.onTap?.call();
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: widget.sub == null
                            ? [
                                DefaultTextStyle(
                                  style: const TextStyle(
                                    fontSize: 19,
                                    color: Colors.black87,
                                  ),
                                  child: widget.main,
                                ),
                              ]
                            : [
                                Expanded(
                                  flex: 3,
                                  child: DefaultTextStyle(
                                    style: const TextStyle(
                                      fontSize: 19,
                                      color: Colors.black87,
                                    ),
                                    child: widget.main,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: DefaultTextStyle(
                                    style: const TextStyle(
                                      color: Colors.grey,
                                    ),
                                    child: widget.sub!,
                                  ),
                                ),
                              ],
                      ),
                    ),
                    widget.action == null
                        ? const SizedBox.shrink()
                        : widget.action!.call(widget.value)
                  ],
                ),
              ),
            ),
            widget.separate
                ? const Divider(
                    thickness: 1,
                    height: 1,
                    color: Color.fromRGBO(232, 228, 228, 1.0),
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
