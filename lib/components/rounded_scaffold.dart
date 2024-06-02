import 'dart:io';

import 'package:clipshare/main.dart';
import 'package:clipshare/util/constants.dart';
import 'package:flutter/material.dart';

class RoundedScaffold extends StatefulWidget {
  final Widget title;
  final Icon icon;
  final Widget child;
  final Widget? floatingActionButton;

  const RoundedScaffold({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.floatingActionButton,
  });

  @override
  State<StatefulWidget> createState() {
    return _RoundedScaffoldState();
  }
}

class _RoundedScaffoldState extends State<RoundedScaffold> {
  bool get isSmallScreen =>
      MediaQuery.of(App.context).size.width <= Constants.smallScreenWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //半透明解决弹窗圆角问题
      backgroundColor: isSmallScreen ? App.bgColor : Colors.transparent,
      appBar: isSmallScreen
          ? AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: widget.title,
            )
          : null,
      body: Column(
        children: [
          Visibility(
            visible: !isSmallScreen,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                child: Row(
                  children: [
                    widget.icon,
                    const SizedBox(
                      width: 5,
                    ),
                    Expanded(
                      child: DefaultTextStyle(
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontFamily:
                              Platform.isWindows ? 'Microsoft YaHei' : null,
                        ),
                        child: widget.title,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Ink(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                color: App.bgColor,
              ),
              child: widget.child,
            ),
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }
}
