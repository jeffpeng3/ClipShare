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
  final void Function()? onDoubleTap;

  SettingCard({
    super.key,
    required this.main,
    required this.value,
    this.sub,
    this.action,
    this.separate = false,
    this.showValueInSub = false,
    this.onTap,
    this.onDoubleTap,
    this.borderRadius = BorderRadius.zero,
    this.show,
  });

  @override
  State<StatefulWidget> createState() {
    return _SettingCardState<T>();
  }
}

class _SettingCardState<T> extends State<SettingCard<T>> {
  bool _readyDoubleClick = false;

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
            if (widget.onDoubleTap == null) {
              //未设置双击，直接执行单击
              widget.onTap?.call();
            } else {
              //设置了双击，且已经点击过一次，执行双击逻辑
              if (_readyDoubleClick) {
                widget.onDoubleTap!.call();
                //双击结束，恢复状态
                _readyDoubleClick = false;
              } else {
                _readyDoubleClick = true;
                //设置了双击，但仅点击了一次，延迟一段时间
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (_readyDoubleClick) {
                    //指定时间后仍然没有进行第二次点击，进行单击逻辑
                    widget.onTap?.call();
                  }
                  //指定时间后无论是否双击，恢复状态
                  _readyDoubleClick = false;
                });
              }
            }
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
