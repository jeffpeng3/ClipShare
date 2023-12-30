import 'package:clipshare/entity/dev_info.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/crypto.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

import '../components/device_card.dart';
import '../dao/device_dao.dart';
import '../db/db_util.dart';
import '../entity/tables/device.dart';
import '../listeners/socket_listener.dart';
import '../util/print_util.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> implements DevAliveObserver {
  final List<DevInfo> _devList = List.empty(growable: true);
  final List<DevInfo> _pairedList = List.empty(growable: true);
  bool _pairingFailed = false;
  bool _pairing = false;
  late DeviceDao _deviceDao;
  final String tag = "DevicesPage";

  @override
  void initState() {
    SocketListener.inst.then((inst) {
      inst.addDevAliveListener(this);
    });
    _deviceDao = DBUtil.inst.deviceDao;
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
    List<Widget> discoverList = [];
    for (var element in _devList) {
      discoverList.add(DeviceCard(
        devInfo: element,
        onTap: () {
          requestPairing(element);
        },
      ));
    }
    List<Widget> pList = [];
    for (var element in _pairedList) {
      pList.add(DeviceCard(
        devInfo: element,
      ));
    }
    return Column(
      children: <Widget>[
        _pairedList.isEmpty
            ? const SizedBox.shrink()
            : Column(
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
                        )
                      ],
                    ),
                  ),
                  ...pList
                ],
              ),
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
              IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.add,
                    size: 20,
                  ))
            ],
          ),
        ),
        _devList.isEmpty
            ? const DeviceCard(devInfo: null)
            : Column(
                children: discoverList,
              ),
      ],
    );
  }

  void onStateChanged() {
    setState(() {});
  }

  void requestPairing(DevInfo dev) {
    SocketListener.inst.then((inst) {
      inst.sendData(dev.guid, MsgKey.requestPairing, {});
    });
    _pairing = false;
    _pairingFailed = false;
    setState(() {});
    var result = showDialog(
      context: context,
      builder: (context) {
        final TextEditingController pinCtr = TextEditingController();
        bool completedInputPin = false;
        bool showTimeoutText = false;
        const focusedBorderColor = Color.fromRGBO(23, 171, 144, 1);
        const submittedColor = Color.fromRGBO(114, 178, 238, 1);
        final defaultPinTheme = PinTheme(
          width: 40,
          height: 40,
          textStyle: const TextStyle(
              fontSize: 20, color: submittedColor, fontWeight: FontWeight.w600),
          decoration: BoxDecoration(
            border: Border.all(color: submittedColor),
            borderRadius: BorderRadius.circular(8),
          ),
        );
        return StatefulBuilder(builder: (context, state) {
          return AlertDialog(
            title: const Text("请输入配对码"),
            contentPadding: const EdgeInsets.all(8),
            content: Container(
              height: 90,
              constraints: const BoxConstraints(minWidth: 500),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(
                  height: 30,
                ),
                Pinput(
                  controller: pinCtr,
                  autofocus: true,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      border: Border.all(color: focusedBorderColor),
                    ),
                  ),
                  submittedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      border: Border.all(color: submittedColor),
                    ),
                  ),
                  errorPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        border: Border.all(color: Colors.redAccent),
                      ),
                      textStyle: defaultPinTheme.textStyle!
                          .copyWith(color: Colors.redAccent)),
                  pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                  showCursor: true,
                  onChanged: (pin) {
                    completedInputPin = pin.length == 4;
                    state(() {});
                  },
                ),
                (showTimeoutText || _pairingFailed)
                    ? Text(
                        showTimeoutText ? "配对超时！" : "配对码错误",
                        textAlign: TextAlign.left,
                        style: const TextStyle(color: Colors.redAccent),
                      )
                    : const SizedBox()
              ]),
            ),
            actions: [
              TextButton(
                  onPressed: _pairing
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: const Text("取消")),
              _pairing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                      ),
                    )
                  : TextButton(
                      onPressed: completedInputPin
                          ? () {
                              String pin = pinCtr.text;
                              SocketListener.inst.then((inst) {
                                inst.sendData(dev.guid, MsgKey.pairing,
                                    {"code": CryptoUtil.toMD5(pin)});
                              });
                              _pairing = true;
                              showTimeoutText = false;
                              Future.delayed(const Duration(seconds: 5), () {
                                if (_pairing) {
                                  _pairing = false;
                                  showTimeoutText = true;
                                  state(() {});
                                }
                              });
                              state(() {});
                            }
                          : null,
                      child: const Text("配对!")),
            ],
          );
        });
      },
    );
    result.then((value) {
      _pairing = false;
      setState(() {});
    });
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
  void onPaired(DevInfo dev, String uid, bool result) {
    if (!result) {
      _pairingFailed = true;
      _pairing = false;
      setState(() {});
      return;
    }
    //关闭配对弹窗
    Navigator.of(context).pop();
    var data =
        Device(guid: dev.guid, devName: dev.name, uid: uid, type: dev.type);
    //新设备
    _deviceDao.add(data).then((v) {
      if (v == 0) {
        PrintUtil.debug(tag, "Device information addition failed");
        return;
      }
      //保存成功，从连接列表中移除
      var pairedDev = _devList.firstWhere((dev) => dev.guid == dev.guid);
      _devList.remove(pairedDev);
      //添加到已配对列表
      _pairedList.add(pairedDev);
      setState(() {});
    });
  }
}
