import 'dart:convert';
import 'dart:io';

import 'package:clipshare/app/data/enums/forward_msg_type.dart';
import 'package:clipshare/app/data/models/forward_server_config.dart';
import 'package:clipshare/app/handlers/socket/forward_socket_client.dart';
import 'package:clipshare/app/services/config_service.dart';
import 'package:clipshare/app/utils/extensions/string_extension.dart';
import 'package:clipshare/app/utils/global.dart';
import 'package:clipshare/app/utils/log.dart';
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
  final tag = "ForwardServerEditDialog";
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
      useKey = true;
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

  void checkConn() {
    ForwardSocketClient.connect(
      ip: hostEditor.text,
      port: portEditor.text.toInt(),
      onConnected: (client) {
        final data = ForwardSocketClient.baseMsg
          ..addAll({
            "connType": ForwardConnType.check.name,
          });
        if (useKey) {
          data["key"] = keyEditor.text;
        }
        client.send(data);
      },
      onDone: (client) {
        setState(() {
          detecting = false;
        });
      },
      onMessage: (client, data) {
        Map<String, dynamic> json = jsonDecode(data);
        if (!json.containsKey("result")) {
          Global.showTipsDialog(
            context: context,
            text: data,
            title: "未知的返回结果",
          );
        } else {
          String result = json['result'];
          if (result != "success") {
            Global.showTipsDialog(
              context: context,
              text: result,
              title: "连接失败",
            );
          } else {
            if (json.containsKey("unlimited")) {
              Global.showTipsDialog(
                context: context,
                text: "白名单设备无任何限制",
                title: "连接成功",
              );
              return;
            }
            if (!json.containsKey("deviceLimit")) {
              String content = "公开服务器\n";
              if (json.containsKey("fileSyncRate")) {
                content += "文件同步限速：${json["fileSyncRate"]} KB/s";
              } else if (json.containsKey("fileSyncNotAllowed")) {
                content += "该中转服务器不可进行文件同步";
              } else {
                content += "无任何限制";
              }
              Global.showTipsDialog(
                context: context,
                text: content,
                title: "连接成功",
              );
              return;
            }
            String deviceLimit = json["deviceLimit"];
            if (deviceLimit == "∞") {
              deviceLimit = "无限制";
            } else {
              deviceLimit += " 台";
            }
            String lifeSpan = json["lifeSpan"];
            if (lifeSpan == "∞") {
              lifeSpan = "无限制";
            } else {
              lifeSpan += " 天";
            }
            String rate = json["rate"];
            if (rate == "∞") {
              rate = "无限制";
            } else {
              rate += " KB/s";
            }
            String remaining = json["remaining"];
            if (remaining == "-1") {
              remaining = "未开始计时";
            } else if (remaining != "0") {
              remaining =
                  "${(remaining.toDouble() / (24 * 60 * 60)).toStringAsFixed(2)} 天";
            } else {
              remaining = "已耗尽";
            }
            String remark = json["remark"];
            String content = ""
                "设备同时连接限制：$deviceLimit\n"
                "有效期：$lifeSpan\n"
                "剩余时间：$remaining\n"
                "速率限制：$rate\n";
            if (remark.isNotEmpty) {
              content += "备注：\n$remark\n";
            }
            Global.showTipsDialog(
              context: context,
              text: content,
              title: "连接成功",
            );
          }
        }
        client.destroy();
      },
      onError: (err, client) {
        Log.error(tag, "onError $err");
        Global.showTipsDialog(
          context: context,
          text: err.toString(),
          title: "连接失败",
        );
        setState(() {
          detecting = false;
        });
      },
    ).catchError((err) {
      Global.showTipsDialog(
        context: context,
        text: (err as SocketException).message,
        title: "连接失败",
      );
      setState(() {
        detecting = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("配置中转服务器"),
      content: SizedBox(
        width: 350,
        child: IntrinsicHeight(
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
                  checkConn();
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
