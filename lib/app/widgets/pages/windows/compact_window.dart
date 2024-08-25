import 'package:clipshare/app/widgets/pages/compact_page.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';

class CompactWindow extends StatefulWidget {
  final WindowController windowController;
  final Map? args;

  const CompactWindow({
    super.key,
    required this.windowController,
    required this.args,
  });

  @override
  State<StatefulWidget> createState() {
    return _CompactWindowState();
  }
}

class _CompactWindowState extends State<CompactWindow> {
  @override
  Widget build(BuildContext context) {
    return const CompactPage();
  }
}
