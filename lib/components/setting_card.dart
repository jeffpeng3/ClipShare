import 'package:flutter/material.dart';

class SettingCard<T> extends StatefulWidget {
  final T value;
  final Widget main;
  final Widget? sub;
  final Widget Function(T val)? action;
  bool separate;
  final bool showValueInSub;
  late BorderRadius borderRadius;
  final bool Function(T)? show;
  final void Function()? onTap;

  SettingCard({
    super.key,
    required this.main,
    required this.value,
    this.sub,
    this.action,
    this.separate = false,
    this.showValueInSub = false,
    this.onTap,
    this.borderRadius = BorderRadius.zero,
    this.show,
  });

  @override
  State<StatefulWidget> createState() {
    return _SettingCardState<T>();
  }
}

class _SettingCardState<T> extends State<SettingCard<T>> {
  @override
  Widget build(BuildContext context) {
    //不显示内容
    if (widget.show != null && !widget.show!.call(widget.value)) {
      return const SizedBox.shrink();
    }
    Widget? sub = widget.sub;
    if (widget.showValueInSub) {
      sub = Text(widget.value.toString());
    }
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: () {
            widget.onTap?.call();
          },
          mouseCursor: SystemMouseCursors.basic,
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
                          children: sub == null
                              ? [
                                  DefaultTextStyle(
                                    style: const TextStyle(
                                      fontSize: 17,
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
                                        fontSize: 17,
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
                                      child: sub,
                                    ),
                                  ),
                                ],
                        ),
                      ),
                      IntrinsicWidth(
                        child: widget.action == null
                            ? const SizedBox.shrink()
                            : widget.action!.call(widget.value),
                      ),
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
      ),
    );
  }
}
