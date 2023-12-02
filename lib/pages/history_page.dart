import 'dart:ffi';

import 'package:clipshare/components/clip_data_card.dart';
import 'package:clipshare/entity/clip_data.dart';
import 'package:clipshare/entity/tables/history.dart';
import 'package:clipshare/listener/ClipListener.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with WidgetsBindingObserver
    implements ClipObserver {
  final List<ClipData> _list = List.empty(growable: true);
  List<Map<String, dynamic>> types = const [
    {'icon': Icons.home, 'text': 'home'},
    {'icon': Icons.home, 'text': 'home'},
    {'icon': Icons.home, 'text': 'home'},
    {'icon': Icons.home, 'text': 'home'},
  ];

  @override
  void initState() {
    super.initState();
    ClipListener.instance().register(this);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: _list.length,
        itemBuilder: (context, i) {
          return Container(
            padding: const EdgeInsets.only(left: 2, right: 2),
            constraints: const BoxConstraints(maxHeight: 150, minHeight: 80),
            child: ClipDataCard(_list[i]),
          );
        });
  }

  @override
  void onChanged(String content) {
    var clip = ClipData(History(
        userId: 0,
        time: DateTime.now(),
        content: content,
        type: 'Text',
        size: content.length));
    _list.add(clip);
    _list.sort((a, b) => b.data.compareTo(a.data));
    setState(() {});
  }
}
