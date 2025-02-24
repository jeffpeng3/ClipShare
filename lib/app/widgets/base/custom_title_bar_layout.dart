import 'package:clipshare/app/utils/extensions/platform_extension.dart';
import 'package:flutter/material.dart';
import 'package:modern_titlebar_buttons/modern_titlebar_buttons.dart';
import 'package:window_manager/window_manager.dart';

class CustomTitleBarLayout extends StatelessWidget {
  final List<Widget> children;
  final Widget child;

  const CustomTitleBarLayout({
    super.key,
    required this.children,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Visibility(
          visible: PlatformExt.isDesktop,
          child: Row(
            children: [
              Expanded(
                child: DragToMoveArea(
                  child: Row(
                    children: children,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedMinimizeButton(
                    onPressed: () {
                      windowManager.minimize();
                    },
                  ),
                  DecoratedMaximizeButton(
                    onPressed: () {
                      windowManager.maximize();
                    },
                  ),
                  DecoratedCloseButton(
                    onPressed: () {
                      windowManager.hide();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
