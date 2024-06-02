import 'package:clipshare/components/empty_content.dart';
import 'package:clipshare/components/rounded_scaffold.dart';
import 'package:clipshare/components/settings/card/setting_card.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/util/constants.dart';
import 'package:flutter/material.dart';

class RuleSettingPage extends StatefulWidget {
  final SettingCard<Map<String, dynamic>>? Function(
    Map<String, dynamic>,
    Function(Key),
  ) onAdd;
  final Widget Function(Function(Map<String, dynamic>) onChange)
      editDialogLayout;
  final void Function(List<Map<String, dynamic>> result) confirm;
  final List<dynamic> initData;
  final String title;

  const RuleSettingPage({
    super.key,
    required this.onAdd,
    required this.confirm,
    required this.title,
    required this.editDialogLayout,
    required this.initData,
  });

  @override
  State<StatefulWidget> createState() {
    return _RuleSettingPageState();
  }
}

class _RuleSettingPageState extends State<RuleSettingPage> {
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

  bool get isSmallScreen =>
      MediaQuery.of(App.context).size.width <= Constants.smallScreenWidth;

  @override
  Widget build(BuildContext context) {
    return RoundedScaffold(
      title: Row(
        children: [
          Expanded(child: Text(widget.title)),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              var arr = _list.map((e) => e.value).toList();
              widget.confirm.call(arr);
            },
            child: const Text("保存"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("取消"),
          ),
        ],
      ),
      icon: const Icon(Icons.window),
      floatingActionButton: Tooltip(
        message: "添加规则",
        child: FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("添加规则"),
                  content: widget.editDialogLayout.call((data) {
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
      child: _list.isEmpty
          ? const EmptyContent()
          : Padding(
              padding: const EdgeInsets.all(5),
              child: ListView.builder(
                itemCount: _list.length,
                itemBuilder: (context, i) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    child: _list[i],
                  );
                },
              ),
            ),
    );
  }
}
