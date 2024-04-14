import 'package:clipshare/components/large_text.dart';
import 'package:clipshare/util/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlighting/flutter_highlighting.dart';
import 'package:flutter_highlighting/themes/github.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

import '../util/extension.dart';

class ClipContentView extends StatelessWidget {
  static const tag = "ClipContentView";
  final String content;
  final String? language;

  const ClipContentView({super.key, required this.content, this.language});

  @override
  Widget build(BuildContext context) {
    return LargeText(
      text: content,
      blockSize: 5000,
      threshold: 0.3,
      onThresholdChanged: (showText) {
        return Container(
          alignment: Alignment.topLeft,
          child: language != null
              ? HighlightView(
                  showText,
                  languageId: language,
                  theme: githubTheme,
                )
              : SelectableLinkify(
                  textAlign: TextAlign.left,
                  text: showText,
                  options: const LinkifyOptions(humanize: false),
                  linkStyle: const TextStyle(
                    decoration: TextDecoration.none,
                  ),
                  onOpen: (link) async {
                    Log.debug(tag, link.url);
                    if (!PlatformExt.isPC) {
                      link.url.askOpenUrl();
                    } else {
                      link.url.openUrl();
                    }
                  },
                  contextMenuBuilder: (context, editableTextState) {
                    return AdaptiveTextSelectionToolbar.buttonItems(
                      anchors: editableTextState.contextMenuAnchors,
                      buttonItems: <ContextMenuButtonItem>[
                        ContextMenuButtonItem(
                          onPressed: () {
                            editableTextState.copySelection(
                              SelectionChangedCause.toolbar,
                            );
                          },
                          type: ContextMenuButtonType.copy,
                        ),
                        ContextMenuButtonItem(
                          onPressed: () {
                            editableTextState.selectAll(
                              SelectionChangedCause.toolbar,
                            );
                          },
                          type: ContextMenuButtonType.selectAll,
                        ),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }
}
