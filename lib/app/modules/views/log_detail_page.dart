import 'package:clipshare/app/widgets/largeText/large_text.dart';
import 'package:clipshare/app/widgets/rounded_scaffold.dart';
import 'package:flutter/material.dart';

class LogDetailPage extends StatelessWidget {
  final String content;
  final String fileName;

  const LogDetailPage({
    super.key,
    required this.fileName,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return RoundedScaffold(
      title: Text(fileName),
      icon: const Icon(Icons.text_snippet_outlined),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: LargeText(text: content, readonly: true),
      ),
    );
  }
}
