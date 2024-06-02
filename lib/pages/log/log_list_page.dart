import 'dart:io';

import 'package:clipshare/components/empty_content.dart';
import 'package:clipshare/components/loading.dart';
import 'package:clipshare/components/rounded_scaffold.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/pages/log/log_detail_page.dart';
import 'package:clipshare/util/extension.dart';
import 'package:clipshare/util/global.dart';
import 'package:flutter/material.dart';

class LogListPage extends StatefulWidget {
  const LogListPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _LogListPageState();
  }
}

class _LogListPageState extends State<LogListPage> {
  List<File> _logs = [];
  var _init = false;

  @override
  void initState() {
    super.initState();
    loadLogFileList();
  }

  void loadLogFileList() {
    final directory = Directory(App.logsDirPath);
    _logs = [];
    if (!directory.existsSync()) {
      _init = true;
      setState(() {});
      return;
    }
    List<FileSystemEntity> entities = directory.listSync(recursive: false);
    for (var entity in entities) {
      if (entity is File) {
        _logs.add(entity);
      }
    }
    _logs.sort(((a, b) => b.fileName.compareTo(a.fileName)));
    _init = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return RoundedScaffold(
      title: const Text("日志记录"),
      icon: const Icon(Icons.bug_report_outlined),
      child: RefreshIndicator(
        onRefresh: () {
          return Future.delayed(const Duration(milliseconds: 300), () {
            loadLogFileList();
          });
        },
        child: !_init
            ? const Loading()
            : _logs.isEmpty
                ? Stack(
                    children: [
                      ListView(),
                      const EmptyContent(),
                    ],
                  )
                : ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (ctx, i) {
                      return Column(
                        children: [
                          InkWell(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_logs[i].fileName),
                                  Text(
                                    _logs[i].lengthSync().sizeStr,
                                  ),
                                ],
                              ),
                            ),
                            onTap: () {
                              final page = LogDetailPage(logFile: _logs[i]);
                              if (App.isSmallScreen) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => page,
                                  ),
                                );
                              } else {
                                Global.showDialogPage(
                                  context: context,
                                  child: page,
                                  maxWidth: 500,
                                );
                              }
                            },
                          ),
                          Visibility(
                            visible: i != _logs.length - 1,
                            child: const Divider(
                              indent: 16,
                              endIndent: 16,
                              height: 1,
                              thickness: 1,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
      ),
    );
  }
}
