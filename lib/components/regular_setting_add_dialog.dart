import 'package:clipshare/util/extension.dart';
import 'package:flutter/material.dart';

class RegularSettingAddDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onChange;

  const RegularSettingAddDialog({super.key, required this.onChange});

  @override
  State<StatefulWidget> createState() {
    return _RegularSettingAddDialogState();
  }
}

class _RegularSettingAddDialogState extends State<RegularSettingAddDialog> {
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _regularController = TextEditingController();
  final TextEditingController _verifyController = TextEditingController();
  String _tagName = "";
  String _regular = "";
  bool _showTagErr = false;
  bool _showRegularErr = false;
  bool _showVerifyErr = false;
  bool _useVerify = false;

  void _onChange() {
    widget.onChange({
      "name": _tagName,
      "regular": _regular,
    });
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _tagController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: "标签名",
              hintText: "请输入标签名",
              errorText: _showTagErr ? "标签名不能为空" : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (txt) {
              _tagName = txt;
              setState(() {
                _showTagErr = txt == "";
              });
              _onChange();
            },
          ),
          const SizedBox(
            height: 10,
          ),
          TextField(
            controller: _regularController,
            decoration: InputDecoration(
              labelText: "规则",
              hintText: "请输入正则表达式",
              errorText: _showRegularErr ? "规则不能为空" : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (txt) {
              _regular = txt;
              _onChange();
              setState(() {
                _showRegularErr = txt == "";
              });
              setState(() {
                try {
                  _showVerifyErr =
                      !_verifyController.text.matchRegExp(_regular);
                } catch (e) {
                  _showVerifyErr = true;
                }
              });
            },
          ),
          const SizedBox(
            height: 10,
          ),
          CheckboxListTile(
            title: const Text("验证测试"),
            value: _useVerify,
            onChanged: (v) {
              setState(() {
                _useVerify = v ?? false;
              });
            },
          ),
          const SizedBox(
            height: 10,
          ),
          Visibility(
            visible: _useVerify,
            child: TextField(
              controller: _verifyController,
              decoration: InputDecoration(
                labelText: _showVerifyErr ? "验证失败" : "验证",
                hintText: "请输入",
                border: OutlineInputBorder(
                  borderSide: _showVerifyErr
                      ? const BorderSide(color: Colors.red)
                      : const BorderSide(),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: _showVerifyErr
                      ? const BorderSide(color: Colors.red)
                      : const BorderSide(),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: _showVerifyErr
                      ? const BorderSide(color: Colors.red)
                      : const BorderSide(),
                ),
                labelStyle:
                    TextStyle(color: _showVerifyErr ? Colors.red : null),
              ),
              onChanged: (txt) {
                setState(() {
                  try {
                    _showVerifyErr = !txt.matchRegExp(_regular);
                  } catch (e) {
                    _showVerifyErr = true;
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
