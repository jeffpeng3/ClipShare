import 'package:clipshare/listeners/socket_listener.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/extension.dart';
import 'package:clipshare/util/log.dart';
import 'package:flutter/material.dart';

class AddDeviceDialog extends StatefulWidget {
  const AddDeviceDialog({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AddDeviceDialogState();
  }
}

class _AddDeviceDialogState extends State<AddDeviceDialog> {
  final tag = "AddDeviceDialog";
  final _ipEditor = TextEditingController();
  final _portEditor = TextEditingController()..text = Constants.port.toString();
  final _ipErrTxt = "请输入正确的IPv4地址";
  final _portErrTxt = "0-65535";
  var _showIpErr = false;
  var _showPortErr = false;
  var _connecting = false;
  var _connectErr = false;
  Map<String, dynamic> _connectData = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加设备'),
      content: SizedBox(
        width: 250,
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 80,
                      child: TextField(
                        autofocus: true,
                        enabled: !_connecting,
                        controller: _ipEditor,
                        decoration: InputDecoration(
                          labelText: "IP",
                          border: const OutlineInputBorder(),
                          errorText: _showIpErr ? _ipErrTxt : null,
                        ),
                        onChanged: (text) {
                          if (_showIpErr) {
                            setState(() {
                              _showIpErr = false;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: TextField(
                      enabled: !_connecting,
                      controller: _portEditor,
                      decoration: InputDecoration(
                        labelText: "端口",
                        errorText: _showPortErr ? _portErrTxt : null,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (text) {
                        if (_showPortErr) {
                          setState(() {
                            _showPortErr = false;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        Text(
          _connectErr ? "连接失败" : "",
          style: const TextStyle(color: Colors.red),
        ),
        IntrinsicWidth(
          child: Row(
            children: [
              TextButton(
                onPressed: () {
                  if (_connecting) {
                    _connectData['stop'] = true;
                    _connecting = false;
                    setState(() {});
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: const Text("取消"),
              ),
              const SizedBox(
                width: 10,
              ),
              TextButton(
                onPressed: _connecting
                    ? null
                    : () {
                        setState(() {
                          _connectErr = false;
                        });
                        if (!_ipEditor.text.isIPv4) {
                          _showIpErr = true;
                        }
                        if (!_portEditor.text.isPort) {
                          _showPortErr = true;
                        }
                        if (_showIpErr || _showPortErr) {
                          setState(() {});
                          return;
                        }
                        setState(() {
                          _connecting = true;
                          _connectData = {
                            "stop": false,
                            "custom": true,
                          };
                        });
                        SocketListener.inst.manualConnect(
                          _ipEditor.text,
                          port: int.parse(_portEditor.text),
                          onErr: (err) {
                            Log.debug(tag, err);
                            if (_connecting) {
                              setState(() {
                                _connectErr = true;
                                _connecting = false;
                              });
                            }
                          },
                          data: _connectData,
                        ).then((val) {
                          if (_connectErr || _connectData['stop']) {
                            return;
                          }
                          Navigator.pop(context);
                        });
                      },
                child: _connecting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                        ),
                      )
                    : const Text("连接"),
              ),
            ],
          ),
        )
      ],
    );
  }
}
