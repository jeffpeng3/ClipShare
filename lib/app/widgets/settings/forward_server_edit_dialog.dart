import 'package:clipshare/app/data/models/forward_server_config.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForwardServerEditDialog extends StatefulWidget {
  final void Function(ForwardServerConfig serverConfig) onOk;
  final ForwardServerConfig? initValue;

  const ForwardServerEditDialog({
    super.key,
    this.initValue,
    required this.onOk,
  });

  @override
  State<StatefulWidget> createState() => _ForwardServerEditDialogState();
}

class _ForwardServerEditDialogState extends State<ForwardServerEditDialog> {
  final hostEditor = TextEditingController();
  final portEditor = TextEditingController();
  final keyEditor = TextEditingController();
  String? hostErrText;
  String? portErrText;
  String? keyErrText;
  bool useKey = false;
  bool detecting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initValue == null) return;
    hostEditor.text = widget.initValue!.host;
    portEditor.text = widget.initValue!.port.toString();
    if (widget.initValue!.key != null) {
      keyEditor.text = widget.initValue!.key!;
    }
  }

  bool checkHostEditor() {
    hostErrText = !hostEditor.text.isDomain && !hostEditor.text.isIPv4
        ? '请输入合法的域名/ipv4地址'
        : null;
    return hostErrText == null;
  }

  bool checkPortEditor() {
    portErrText = !portEditor.text.isPort ? '请输入合法的端口' : null;
    return portErrText == null;
  }

  bool checkKeyEditor() {
    if (useKey == false) return true;
    keyErrText = keyEditor.text == "" ? '请输入密钥' : null;
    return keyErrText == null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("配置中转服务器"),
      content: IntrinsicHeight(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    enabled: !detecting,
                    controller: hostEditor,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: "域名/ip",
                      labelText: "主机",
                      border: const OutlineInputBorder(),
                      errorText: hostErrText,
                      helperText: "",
                    ),
                    onChanged: (str) {
                      checkHostEditor();
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(
                  width: 4,
                ),
                SizedBox(
                  width: 80,
                  child: TextField(
                    enabled: !detecting,
                    controller: portEditor,
                    decoration: InputDecoration(
                        hintText: "端口",
                        labelText: "端口",
                        border: const OutlineInputBorder(),
                        errorText: portErrText,
                        helperText: "",
                        helperMaxLines: 2),
                    onChanged: (str) {
                      checkPortEditor();
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: CheckboxListTile(
                enabled: !detecting,
                title: const Text("使用密钥"),
                value: useKey,
                onChanged: (v) {
                  if (v == false) {
                    keyEditor.text = "";
                    keyErrText = null;
                  }
                  setState(() {
                    useKey = v ?? false;
                  });
                },
              ),
            ),
            Visibility(
              visible: useKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      enabled: !detecting,
                      keyboardType: TextInputType.multiline,
                      minLines: 3,
                      maxLines: 3,
                      controller: keyEditor,
                      decoration: InputDecoration(
                        hintText: "访问密钥",
                        labelText: "请输入访问密钥",
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        border: const OutlineInputBorder(),
                        errorText: keyErrText,
                        helperText: "",
                      ),
                      onChanged: (str) {
                        checkKeyEditor();
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Visibility(
              visible: !detecting,
              replacement: const Loading(
                width: 20,
              ),
              child: TextButton(
                onPressed: () {
                  detecting = true;
                  setState(() {});
                  Future.delayed(const Duration(seconds: 5)).then(
                    (t) => {
                      setState(() {
                        detecting = false;
                      }),
                    },
                  );
                },
                child: const Text("连接检测"),
              ),
            ),
            IntrinsicWidth(
              child: Row(
                children: [
                  TextButton(
                    onPressed: detecting
                        ? null
                        : () {
                            Navigator.of(context).pop();
                          },
                    child: const Text("取消"),
                  ),
                  TextButton(
                    onPressed: detecting
                        ? null
                        : () {
                            if (hostErrText != null ||
                                portErrText != null ||
                                keyErrText != null) {
                              return;
                            }
                            widget.onOk(
                              ForwardServerConfig(
                                host: hostEditor.text,
                                port: portEditor.text.toInt(),
                                key: useKey ? keyEditor.text : null,
                              ),
                            );
                            Navigator.of(context).pop();
                          },
                    child: const Text("确定"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
