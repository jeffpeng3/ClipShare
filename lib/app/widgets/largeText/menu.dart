import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

class ContextMenuItemWidget extends PopupMenuItem<void>
    implements PreferredSizeWidget {
  ContextMenuItemWidget({
    super.key,
    required String text,
    required VoidCallback super.onTap,
  }) : super(
          child: Text(text),
        );

  @override
  Size get preferredSize => const Size(150, 25);
}

class ContextMenuControllerImpl implements SelectionToolbarController {
  const ContextMenuControllerImpl();

  @override
  void hide(BuildContext context) {}

  @override
  Future<void> show({
    required BuildContext context,
    required CodeLineEditingController controller,
    required TextSelectionToolbarAnchors anchors,
    Rect? renderRect,
    required LayerLink layerLink,
    required ValueNotifier<bool> visibility,
  }) async {
    final selection = controller.selection;
    showMenu(
      context: context,
      position: RelativeRect.fromSize(
        (anchors.secondaryAnchor ?? anchors.primaryAnchor) &
            const Size(150, double.infinity),
        MediaQuery.of(context).size,
      ),
      items: [
        ContextMenuItemWidget(
          text: '复制',
          onTap: () {
            controller.copy();
          },
        ),
        ContextMenuItemWidget(
          text: '选择所有',
          onTap: () {
            controller.selectAll();
          },
        ),
      ],
    );
    Future.delayed(const Duration(milliseconds: 100), () {
      controller.selection = selection;
    });
  }
}
