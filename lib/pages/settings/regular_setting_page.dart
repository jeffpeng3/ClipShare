import 'package:clipshare/components/empty_content.dart';
import 'package:clipshare/components/setting_card.dart';
import 'package:clipshare/main.dart';
import 'package:flutter/material.dart';

class RegularSettingPage extends StatefulWidget {
  final SettingCard<Map<String, dynamic>>? Function(
    Map<String, dynamic>,
    Function(Key),
  ) onAdd;
  final Widget Function(Function(Map<String, dynamic>) onChange)
      renderEditLayout;
  final void Function(List<Map<String, dynamic>> result) confirm;
  final List<dynamic> initData;
  final String title;

  const RegularSettingPage({
    super.key,
    required this.onAdd,
    required this.confirm,
    required this.title,
    required this.renderEditLayout,
    required this.initData,
  });

  @override
  State<StatefulWidget> createState() {
    return _RegularSettingPageState();
  }
}

class _RegularSettingPageState extends State<RegularSettingPage> {
  final List<SettingCard<Map<String, dynamic>>> _list =
      List.empty(growable: true);
  Map<String, dynamic> _addData = {};

  @override
  void initState() {
    super.initState();
    for (var data in widget.initData) {
      _list.add(widget.onAdd.call(data, remove)!);
    }
  }

  void remove(Key key) {
    _list.removeWhere((element) => element.key == key);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: App.bgColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(
          children: [
            Expanded(child: Text(widget.title)),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                var arr = _list.map((e) => e.value).toList();
                widget.confirm.call(arr);
              },
              child: const Text("确定"),
            ),
          ],
        ),
      ),
      body: _list.isEmpty
          ? const EmptyContent()
          : Padding(
              padding: const EdgeInsets.all(5),
              child: ListView.builder(
                itemCount: _list.length,
                itemBuilder: (context, i) {
                  return _list[i];
                },
              ),
            ),
      floatingActionButton: Tooltip(
        message: "添加规则",
        child: FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("添加规则"),
                  content: widget.renderEditLayout.call((data) {
                    _addData = data;
                  }),
                  actions: [
                    TextButton(
                      onPressed: () {
                        _addData = {};
                        Navigator.pop(context);
                      },
                      child: const Text("取消"),
                    ),
                    TextButton(
                      onPressed: () {
                        var customWidget = widget.onAdd(_addData, remove);
                        if (customWidget != null) {
                          Navigator.pop(context);
                          _list.add(customWidget);
                          _addData = {};
                          setState(() {});
                        }
                      },
                      child: const Text("添加"),
                    ),
                  ],
                );
              },
            );
          },
          child: const Icon(Icons.add), // 可以选择其他图标
        ),
      ),
    );
  }
}
