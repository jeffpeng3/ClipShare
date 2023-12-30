import 'package:clipshare/entity/dev_info.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

import '../components/device_card.dart';
import '../listeners/socket_listener.dart';
import 'package:collection/collection.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> implements DevAliveObserver {
  final List<DevInfo> _devList = List.empty(growable: true);
  final List<DevInfo> _pairedList = List.empty(growable: true);

  @override
  void initState() {
    SocketListener.inst.then((inst) {
      inst.addDevAliveListener(this);
    });
    super.initState();
  }

  @override
  void dispose() {
    SocketListener.inst.then((inst) {
      inst.removeDevAliveListener(this);
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _pairedList.isEmpty
            ? const SizedBox.shrink()
            : Expanded(
                child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Row(
                      children: [
                        Text(
                          "我的设备(${_pairedList.length})",
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: "宋体"),
                        ),
                        IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.add,
                              size: 20,
                            ))
                      ],
                    ),
                  ),
                  Expanded(
                      child: ListView.builder(
                          itemCount: _devList.length,
                          itemBuilder: (context, i) {
                            return DeviceCard(
                              devInfo: _devList[i],
                            );
                          }))
                ],
              )),
        _devList.isEmpty
            ? const DeviceCard(devInfo: null)
            : Expanded(
                child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Row(
                      children: [
                        Text(
                          "发现设备(${_devList.length})",
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: "宋体"),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                      child: ListView.builder(
                          itemCount: _devList.length,
                          itemBuilder: (context, i) {
                            return DeviceCard(
                              devInfo: _devList[i],
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    const focusedBorderColor =
                                        Color.fromRGBO(23, 171, 144, 1);
                                    const submittedColor =
                                        Color.fromRGBO(114, 178, 238, 1);
                                    final defaultPinTheme = PinTheme(
                                      width: 40,
                                      height: 40,
                                      textStyle: const TextStyle(
                                          fontSize: 20,
                                          color: submittedColor,
                                          fontWeight: FontWeight.w600),
                                      decoration: BoxDecoration(
                                        border:
                                            Border.all(color: submittedColor),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    );
                                    return AlertDialog(
                                      title: const Text("请输入配对码"),
                                      contentPadding: const EdgeInsets.all(8),
                                      content: Container(
                                        height: 90,
                                        constraints:
                                            const BoxConstraints(minWidth: 500),
                                        child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const SizedBox(
                                                height: 30,
                                              ),
                                              Pinput(
                                                autofocus: true,
                                                defaultPinTheme:
                                                    defaultPinTheme,
                                                focusedPinTheme:
                                                    defaultPinTheme.copyWith(
                                                  decoration: defaultPinTheme
                                                      .decoration!
                                                      .copyWith(
                                                    border: Border.all(
                                                        color:
                                                            focusedBorderColor),
                                                  ),
                                                ),
                                                submittedPinTheme:
                                                    defaultPinTheme.copyWith(
                                                  decoration: defaultPinTheme
                                                      .decoration!
                                                      .copyWith(
                                                    border: Border.all(
                                                        color: submittedColor),
                                                  ),
                                                ),
                                                errorPinTheme:
                                                    defaultPinTheme.copyWith(
                                                        decoration:
                                                            defaultPinTheme
                                                                .decoration!
                                                                .copyWith(
                                                          border: Border.all(
                                                              color: Colors
                                                                  .redAccent),
                                                        ),
                                                        textStyle: defaultPinTheme
                                                            .textStyle!
                                                            .copyWith(
                                                                color: Colors
                                                                    .redAccent)),
                                                pinputAutovalidateMode:
                                                    PinputAutovalidateMode
                                                        .onSubmit,
                                                showCursor: true,
                                                onCompleted: (pin) =>
                                                    print(pin),
                                              ),
                                            ]),
                                      ),
                                      actions: [
                                        TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text("取消")),
                                        TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text("配对!")),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          }))
                ],
              ))
      ],
    );
  }

  @override
  void onConnected(DevInfo info) {
    _devList.firstWhere((dev) => dev.guid == info.guid, orElse: () {
      _devList.add(info);
      return info;
    });
    setState(() {});
  }

  @override
  void onDisConnected(String devId) {
    _devList.removeWhere((dev) => dev.guid == devId);
    setState(() {});
  }

  @override
  void onPaired(String devId) {
    //配对成功，从链接列表中移除
    var pairedDev = _devList.firstWhere((dev) => dev.guid == devId);
    _devList.remove(pairedDev);
    //添加到配对列表
    _pairedList.add(pairedDev);
    setState(() {});
  }
}
