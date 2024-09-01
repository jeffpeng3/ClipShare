import 'package:clipshare/app/utils/constants.dart';
import 'package:clipshare/app/widgets/empty_content.dart';
import 'package:clipshare/app/widgets/rounded_scaffold.dart';
import 'package:clipshare/app/widgets/settings/card/setting_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RuleSettingPage extends StatefulWidget {
  final SettingCard<Map<String, dynamic>>? Function(
    Map<String, dynamic>,
    Function(Key),
  ) onAdd;
  final Widget Function(
    Map<String, dynamic>? initData,
    Function(Map<String, dynamic>) onChange,
  ) editDialogLayout;
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
  Map<String, dynamic> _editData = {};

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.initData.length; i++) {
      final data = widget.initData[i];
      final item = widget.onAdd.call(data, remove)!;
      item.onTap = () => showEditDialog(i, _list[i].value);
      _list.add(item);
    }
  }

  void remove(Key key) {
    _list.removeWhere((element) => element.key == key);
    setState(() {});
  }

  bool get isSmallScreen =>
      MediaQuery.of(Get.context!).size.width <= Constants.smallScreenWidth;

  void showEditDialog(int? idx, Map<String, dynamic>? initData) {
    if (initData != null) {
      _editData = initData;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("添加规则"),
          content: widget.editDialogLayout.call(initData, (data) {
            if (idx == null) {
              _addData = data;
            } else {
              _editData = data;
            }
          }),
          actions: [
            TextButton(
              onPressed: () {
                _addData = {};
                _editData = {};
                Navigator.pop(context);
              },
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () {
                var customWidget =
                    widget.onAdd(idx == null ? _addData : _editData, remove);

                if (customWidget != null) {
                  Navigator.pop(context);
                  int i = idx ?? _list.length;
                  customWidget.onTap = () => showEditDialog(i, _list[i].value);
                  if (idx == null) {
                    _list.add(customWidget);
                  } else {
                    _list[idx] = customWidget;
                  }
                  _addData = {};
                  _editData = {};
                  setState(() {});
                }
              },
              child: Text(idx == null ? "添加" : "修改"),
            ),
          ],
        );
      },
    );
  }

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
            showEditDialog(null, null);
          },
          child: const Icon(Icons.add), // 可以选择其他图标
        ),
      ),
      child: Visibility(
        visible: _list.isEmpty,
        replacement: Padding(
          padding: const EdgeInsets.all(5),
          child: ListView.builder(
            itemCount: _list.length,
            itemBuilder: (context, i) {
              return GestureDetector(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 5),
                  child: _list[i],
                ),
                onTap: () => showEditDialog(i, _list[i].value),
              );
            },
          ),
        ),
        child: const EmptyContent(),
      ),
    );
  }
}
