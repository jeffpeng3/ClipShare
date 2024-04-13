import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class UpdateLogPage extends StatelessWidget {
  const UpdateLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: rootBundle.loadString("assets/md/updateLogs.md"),
      builder: (context, v) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 7, 15, 7),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "更新日志",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold,),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Markdown(
                data: v.data ?? "读取失败！",
                selectable: true,
                onSelectionChanged: (
                  String? text,
                  TextSelection selection,
                  SelectionChangedCause? cause,
                ) {},
              ),
            ),
          ],
        );
      },
    );
  }
}
