import 'dart:io';

import 'package:clipshare/app/utils/extension.dart';
import 'package:clipshare/app/widgets/rounded_scaffold.dart';
import 'package:flutter/material.dart';

class LogDetailPage extends StatelessWidget {
  final File logFile;

  const LogDetailPage({super.key, required this.logFile});

  @override
  Widget build(BuildContext context) {
    return RoundedScaffold(
      title: Text(logFile.fileName),
      icon: const Icon(Icons.text_snippet_outlined),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(logFile.readAsStringSync()),
        ),
      ),
    );
  }
}
