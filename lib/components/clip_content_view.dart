import 'package:clipshare/util/log.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

import '../util/extension.dart';

class ClipContentView extends StatelessWidget{
  static const tag = "ClipContentView";
  final String content;
  const ClipContentView({super.key,required this.content});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      clipBehavior: Clip.antiAlias,
      child: Container(
        alignment: Alignment.topLeft,
        child: SelectableLinkify(
          textAlign: TextAlign.left,
          text: content,
          options: const LinkifyOptions(humanize: false),
          linkStyle: const TextStyle(
            decoration: TextDecoration.none,
          ),
          onOpen: (link) async {
            Log.debug(tag, link.url);
            if(!PlatformExt.isPC) {
              link.url.askOpenUrl();
            }else{
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
      ),
    );
  }

}