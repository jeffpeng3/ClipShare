import 'dart:io';

import 'package:clipshare/components/large_text.dart';
import 'package:clipshare/entity/clip_data.dart';
import 'package:clipshare/pages/preview_page.dart';
import 'package:clipshare/util/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlighting/flutter_highlighting.dart';
import 'package:flutter_highlighting/themes/github.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:open_file_plus/open_file_plus.dart';

import '../util/extension.dart';

class ClipContentView extends StatefulWidget {
  final ClipData clipData;
  final String? language;

  const ClipContentView({super.key, required this.clipData, this.language});

  @override
  State<StatefulWidget> createState() {
    return _ClipContentViewState();
  }
}

class _ClipContentViewState extends State<ClipContentView> {
  static const tag = "ClipContentView";

  @override
  Widget build(BuildContext context) {
    return widget.clipData.isText
        ? LargeText(
            text: widget.clipData.data.content,
            blockSize: 5000,
            bottomThreshold: 0.3,
            onThresholdChanged: (showText) {
              return Container(
                alignment: Alignment.topLeft,
                child: widget.language != null
                    ? HighlightView(
                        showText,
                        languageId: widget.language,
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
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: InkWell(
                  child: Image.file(
                    File(widget.clipData.data.content),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PreviewPage(
                          clip: widget.clipData,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
  }
}
