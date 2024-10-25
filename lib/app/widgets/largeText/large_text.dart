import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

import 'find.dart';
import 'menu.dart';

class LargeText extends StatefulWidget {
  final String text;
  final bool readonly;
  final bool showLineNumber;
  final bool showSperator;

  const LargeText({
    super.key,
    required this.text,
    required this.readonly,
    this.showLineNumber = false,
    this.showSperator = false,
  });

  @override
  State<StatefulWidget> createState() => _LargeTextState();
}

class _LargeTextState extends State<LargeText> {
  final CodeLineEditingController _controller = CodeLineEditingController();

  @override
  void initState() {
    _controller.text = widget.text;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CodeEditor(
      readOnly: widget.readonly,
      controller: _controller,
      wordWrap: true,
      indicatorBuilder:
          (context, editingController, chunkController, notifier) {
        return Row(
          children: [
            Visibility(
              visible: widget.showLineNumber,
              child: DefaultCodeLineNumber(
                controller: editingController,
                notifier: notifier,
              ),
            ),
            DefaultCodeChunkIndicator(
              width: 20,
              controller: chunkController,
              notifier: notifier,
            ),
          ],
        );
      },
      findBuilder: (context, controller, readOnly) =>
          CodeFindPanelView(controller: controller, readOnly: readOnly),
      toolbarController: const ContextMenuControllerImpl(),
      sperator: Visibility(
        visible: widget.showSperator,
        child: Container(width: 1, color: const Color(0xADADAFB6)),
      ),
    );
  }
}
