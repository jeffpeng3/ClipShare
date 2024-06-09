import 'dart:convert';

import 'package:clipshare/channels/multi_window_channel.dart';
import 'package:clipshare/components/add_device_dialog.dart';
import 'package:clipshare/components/device_card.dart';
import 'package:clipshare/dao/device_dao.dart';
import 'package:clipshare/db/app_db.dart';
import 'package:clipshare/entity/dev_info.dart';
import 'package:clipshare/entity/message_data.dart';
import 'package:clipshare/entity/tables/device.dart';
import 'package:clipshare/entity/tables/operation_record.dart';
import 'package:clipshare/entity/tables/operation_sync.dart';
import 'package:clipshare/entity/version.dart';
import 'package:clipshare/listeners/socket_listener.dart';
import 'package:clipshare/main.dart';
import 'package:clipshare/provider/device_info_provider.dart';
import 'package:clipshare/util/constants.dart';
import 'package:clipshare/util/crypto.dart';
import 'package:clipshare/util/extension.dart';
import 'package:clipshare/util/global.dart';
import 'package:clipshare/util/log.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:refena_flutter/refena_flutter.dart';

class DevicesPage extends StatefulWidget {
  static final GlobalKey<DevicesPageState> pageKey =
      GlobalKey<DevicesPageState>();

  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => DevicesPageState();
}

class DevicesPageState extends State<DevicesPage>
    with SingleTickerProviderStateMixin
    implements DevAliveListener, SyncListener, DiscoverListener {
  final List<DeviceCard> _discoverList = List.empty(growable: true);
  final List<DeviceCard> _pairedList = List.empty(growable: true);
  late StateSetter _pairingState;
  bool _pairingFailed = false;
  bool _pairing = false;
  bool _discovering = true;
  late DeviceDao _deviceDao;
  late AnimationController _rotationController;
  var _rotationReverse = false;
  late Animation<double> _animation;
  final String tag = "DevicesPage";
  late Ref _ref;

  @override
  void initState() {
    super.initState();
    SocketListener.inst.addDevAliveListener(this);
    SocketListener.inst.addDiscoverListener(this);
    SocketListener.inst.addSyncListener(Module.device, this);
    // 旋转动画
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _setRotationAnimation();
    _deviceDao = AppDb.inst.deviceDao;
    _deviceDao.getAllDevices(App.userId).then((list) {
      _pairedList.clear();
      for (var dev in list) {
        if (!dev.isPaired) {
          continue;
        }
        _pairedList.add(
          DeviceCard(
            dev: dev,
            isPaired: true,
            onTap: (device, isConnected, showReNameDlg) {
              if (PlatformExt.isPC) {
                _showBottomDetailSheet(device, isConnected, showReNameDlg);
              }
            },
            onLongPress: (device, isConnected, showReNameDlg) {
              if (PlatformExt.isMobile) {
                _showBottomDetailSheet(device, isConnected, showReNameDlg);
              }
            },
            isConnected: false,
            isSelf: false,
            minVersion: null,
            version: null,
          ),
        );
      }
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        _ref = context.ref;
      });
    });
  }

  @override
  void dispose() {
    SocketListener.inst.removeDevAliveListener(this);
    SocketListener.inst.removeSyncListener(Module.device, this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Column(
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
                                fontFamily: "宋体",
                              ),
                            ),
                          ],
                        ),
                      ),
                      ..._pairedList,
                    ],
                  ),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                children: [
                  Text(
                    "发现设备(${_discoverList.length})",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Tooltip(
                    message: "重新发现设备",
                    child: RotationTransition(
                      turns: _animation,
                      child: IconButton(
                        onPressed: () {
                          if (_discovering) {
                            _rotationReverse = !_rotationReverse;
                            _setRotationAnimation();
                            SocketListener.inst.restartDiscoverDevice();
                          } else {
                            SocketListener.inst.startDiscoverDevice();
                          }
                          setState(() {});
                        },
                        icon: const Icon(
                          Icons.sync,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Tooltip(
                    message: "手动添加设备",
                    child: IconButton(
                      onPressed: () {
                        _showAddDeviceDialog();
                      },
                      icon: const Icon(
                        Icons.add,
                        size: 20,
                      ),
                    ),
                  ),
                  _discovering
                      ? Tooltip(
                          message: "停止发现",
                          child: IconButton(
                            onPressed: () {
                              SocketListener.inst.stopDiscoverDevice();
                            },
                            icon: const Icon(
                              Icons.stop,
                              size: 20,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
            _discoverList.isEmpty
                ? const DeviceCard(
                    dev: null,
                    isPaired: false,
                    isConnected: false,
                    isSelf: false,
                    minVersion: null,
                    version: null,
                  )
                : Column(
                    children: _discoverList,
                  ),
          ],
        ),
      ],
    );
  }

  List<Device> getCompatibleOnlineDevices() {
    List<Device> res = List.empty(growable: true);
    for (var dev in _pairedList) {
      if (dev.isConnected && dev.isVersionCompatible) {
        res.add(dev.dev!);
      }
    }
    return res;
  }

  void _showBottomDetailSheet(
    Device device,
    bool isConnected,
    void Function() showReNameDlg,
  ) {
    showModalBottomSheet(
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      context: context,
      elevation: 100,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          constraints: const BoxConstraints(minWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Constants.devTypeIcons[device.type]!.icon,
                        color: isConnected ? Colors.lightBlue : Colors.grey,
                        size: Constants.devTypeIcons[device.type]!.size,
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name,
                            style: const TextStyle(fontSize: 25),
                          ),
                          Text(
                            device.address ?? "",
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        splashColor: Colors.black12,
                        onTap: showReNameDlg,
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.only(top: 5, bottom: 5),
                          child: Column(
                            children: [
                              Icon(Icons.edit_note_rounded),
                              Text("重命名"),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          var devInfo = DevInfo.fromDevice(device);
                          if (isConnected) {
                            SocketListener.inst.disConnectDevice(
                              devInfo,
                              true,
                            );
                          } else {
                            var address = device.address;
                            var [ip, port] = address!.split(":");
                            SocketListener.inst
                                .manualConnect(ip, port: port.toInt());
                          }
                          Navigator.pop(context);
                        },
                        splashColor: Colors.black12,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 5, bottom: 5),
                          child: Column(
                            children: [
                              Icon(
                                isConnected
                                    ? Icons.link_off_outlined
                                    : Icons.link,
                              ),
                              Text(isConnected ? "断开连接" : "重新连接"),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Global.showTipsDialog(
                            context: context,
                            text: "是否要取消配对？",
                            onOk: () {
                              if (isConnected) {
                                var devInfo = DevInfo.fromDevice(device);
                                SocketListener.inst.onDevForget(
                                  devInfo,
                                  App.userId,
                                );
                                SocketListener.inst.sendData(
                                  devInfo,
                                  MsgType.forgetDev,
                                  {},
                                );
                              }
                              //更新配对状态为未配对
                              device.isPaired = false;
                              //更新UI
                              setState(() {});
                              AppDb.inst.deviceDao.updateDevice(device);
                              Navigator.pop(context);
                            },
                            showCancel: true,
                          );
                        },
                        splashColor: Colors.black12,
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.only(top: 5, bottom: 5),
                          child: Column(
                            children: [
                              Icon(Icons.block_flipped),
                              Text("取消配对"),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // IconButton(onPressed: (){}, icon: const Icon(Icons.edit_note))
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  ///请求配对设备
  void _requestPairing(DevInfo dev) {
    SocketListener.inst.sendData(dev, MsgType.reqPairing, {});
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
            fontSize: 20,
            color: submittedColor,
            fontWeight: FontWeight.w600,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: submittedColor),
            borderRadius: BorderRadius.circular(8),
          ),
        );
        return StatefulBuilder(
          builder: (context, state) {
            _pairingState = state;
            return AlertDialog(
              title: const Text("请输入配对码"),
              contentPadding: const EdgeInsets.all(8),
              content: Container(
                height: 90,
                constraints: const BoxConstraints(minWidth: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      height: 30,
                    ),
                    Pinput(
                      length: 6,
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
                            .copyWith(color: Colors.redAccent),
                      ),
                      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                      showCursor: true,
                      onChanged: (pin) {
                        completedInputPin = pin.length == 6;
                        state(() {});
                      },
                    ),
                    (showTimeoutText || _pairingFailed)
                        ? Text(
                            showTimeoutText ? "配对超时！" : "配对码错误",
                            textAlign: TextAlign.left,
                            style: const TextStyle(color: Colors.redAccent),
                          )
                        : const SizedBox(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _pairing
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: const Text("取消"),
                ),
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
                                SocketListener.inst.sendData(
                                  dev,
                                  MsgType.pairing,
                                  {"code": CryptoUtil.toMD5(pin)},
                                );
                                _pairing = true;
                                showTimeoutText = false;
                                _pairingFailed = false;
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
                        child: const Text("配对!"),
                      ),
              ],
            );
          },
        );
      },
    );
    result.then((value) {
      _pairing = false;
      setState(() {});
    });
  }

  @override
  void onConnected(DevInfo info, Version minVersion, Version version) async {
    var dev = await Device.fromDevInfo(info);
    for (var i = 0; i < _pairedList.length; i++) {
      var paired = _pairedList[i];
      if (paired.dev == dev) {
        //修改widget状态
        paired.dev!.address = dev!.address;
        _pairedList[i] = paired.copyWith(
          isConnected: true,
          dev: paired.dev,
          minVersion: minVersion,
          version: version,
        );
        setState(() {});
        _notifyOnlineDevicesWindow();
        //是已配对的设备，请求所有缺失数据
        // SocketListener.inst.sendData(null, MsgType.reqMissingData, {});
        return;
      }
    }
    var hasSame = _discoverList.firstWhereOrNull(
          (element) => element.dev?.guid == info.guid,
        ) !=
        null;
    if (hasSame) {
      return;
    }
    _discoverList.add(
      DeviceCard(
        dev: Device(
          guid: info.guid,
          devName: info.name,
          uid: 0,
          type: info.type,
        ),
        onTap: (device, isConnected, showReNameDlg) => _requestPairing(info),
        minVersion: minVersion,
        version: version,
        isPaired: false,
        isConnected: true,
        isSelf: false,
      ),
    );
    setState(() {});
  }

  @override
  void onForget(DevInfo dev, int uid) {
    //忘记设备，从已配对列表移动到发现设备列表
    var forgetDev = _pairedList.firstWhereOrNull(
      (element) => element.dev?.guid == dev.guid,
    );
    _pairedList.removeWhere(
      (element) => element.dev?.guid == dev.guid,
    );
    forgetDev = forgetDev?.copyWith(isPaired: false);
    if (forgetDev?.isConnected ?? false) {
      // 已经连接，minVersion必定不空
      onConnected(dev, forgetDev!.minVersion!, forgetDev.version!);
    }
    setState(() {});
    _notifyOnlineDevicesWindow();
  }

  @override
  void onDisConnected(String devId) {
    _discoverList.removeWhere((dev) => dev.dev?.guid == devId);
    for (var i = 0; i < _pairedList.length; i++) {
      var dev = _pairedList[i];
      if (dev.dev?.guid == devId) {
        _pairedList[i] = dev.copyWith(
          isConnected: false,
          minVersion: null,
          version: null,
        );
      }
    }
    setState(() {});
    _notifyOnlineDevicesWindow();
  }

  @override
  void onPaired(DevInfo dev, int uid, bool result, String? address) async {
    if (!result) {
      Log.debug(tag, "_pairingFailed $_pairingFailed");
      _pairingFailed = true;
      _pairing = false;
      setState(() {});
      _pairingState(() {});
      return;
    }
    //关闭配对弹窗
    Navigator.of(context).pop();
    //已配对，请求所有缺失数据
    SocketListener.inst.reqMissingData();
    var newDev = Device(
      guid: dev.guid,
      devName: dev.name,
      uid: uid,
      type: dev.type,
      isPaired: true,
      address: address,
    );
    var dbDev = await _deviceDao.getById(dev.guid, App.userId);
    if (dbDev != null) {
      //之前配对过，只是取消配对了
      dbDev.isPaired = true;
      _ref.notifier(DeviceInfoProvider.inst).addOrUpdate(dbDev).then((res) {
        if (res) {
          _addPairedDevInPage(dbDev);
          return;
        }
        Global.snackBarErr(context, "设备添加失败");
      });
    } else {
      //新设备
      _ref.notifier(DeviceInfoProvider.inst).addOrUpdate(newDev).then((res) {
        if (!res) {
          Log.debug(tag, "Device information addition failed");
          Global.snackBarErr(context, "设备添加失败");
          return;
        }
        _addPairedDevInPage(newDev);
      });
    }
  }

  void _notifyOnlineDevicesWindow() {
    //通知弹窗更新设备列表
    final onlineDevicesWindow = App.onlineDevicesWindow;
    if (onlineDevicesWindow != null) {
      MultiWindowChannel.notify(onlineDevicesWindow.windowId);
    }
  }

  void _addPairedDevInPage(Device dev) {
    //配对成功，从连接列表中移除
    var discoverDev =
        _discoverList.firstWhere((ele) => ele.dev?.guid == dev.guid);
    _discoverList.removeWhere((ele) => ele.dev?.guid == dev.guid);
    //添加到已配对列表
    _pairedList.add(
      discoverDev.copyWith(
        dev: dev,
        isPaired: true,
        isConnected: true,
        onTap: (device, isConnected, showReNameDlg) {
          if (PlatformExt.isPC) {
            _showBottomDetailSheet(device, isConnected, showReNameDlg);
          }
        },
        onLongPress: (device, isConnected, showReNameDlg) {
          if (PlatformExt.isMobile) {
            _showBottomDetailSheet(device, isConnected, showReNameDlg);
          }
        },
      ),
    );
    setState(() {});
  }

  @override
  void ackSync(MessageData msg) {
    var send = msg.send;
    var data = msg.data;
    var opSync =
        OperationSync(opId: data["id"], devId: send.guid, uid: App.userId);
    //记录同步记录
    AppDb.inst.opSyncDao.add(opSync);
  }

  @override
  void onSync(MessageData msg) {
    var send = msg.send;
    var opRecord = OperationRecord.fromJson(msg.data);
    Map<String, dynamic> json = jsonDecode(opRecord.data);
    Device dev = Device.fromJson(json);
    Future f = Future(() => null);
    if (dev.guid != App.devInfo.guid) {
      switch (opRecord.method) {
        case OpMethod.add:
          f = AppDb.inst.deviceDao.add(dev);
          break;
        case OpMethod.delete:
          AppDb.inst.deviceDao.remove(dev.guid, App.userId);
          break;
        case OpMethod.update:
          f = AppDb.inst.deviceDao.updateDevice(dev);
          break;
        default:
          return;
      }
    }
    //发送同步确认
    f.then(
      (v) => SocketListener.inst.sendData(
        send,
        MsgType.ackSync,
        {"id": opRecord.id, "module": Module.device.moduleName},
      ),
    );
  }

  @override
  void onDiscoverStart() {
    _rotationController.repeat();
    setState(() {
      _discovering = true;
    });
    Log.debug(tag, "onDiscoverStart");
  }

  @override
  void onDiscoverFinished() {
    setState(() {
      _discovering = false;
    });
    Log.debug(tag, "onDiscoverFinished");
    _rotationReverse = false;
    _setRotationAnimation();
    _rotationController.stop();
  }

  ///设置旋转动画
  void _setRotationAnimation() {
    _animation = Tween<double>(
      begin: 0.0,
      end: 1 * (_rotationReverse ? -1 : 1),
    ).animate(_rotationController);
  }

  ///显示添加设备弹窗
  void _showAddDeviceDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => const AddDeviceDialog(),
    );
  }
}
