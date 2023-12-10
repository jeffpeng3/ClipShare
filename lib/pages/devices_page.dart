import 'package:clipshare/entity/dev_info.dart';
import 'package:flutter/material.dart';

import '../components/device_card.dart';
import '../listeners/socket_listener.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> implements DevAliveObserver {
  final List<DevInfo> _devList = List.empty(growable: true);

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
    return ListView.builder(
        itemCount: _devList.length,
        itemBuilder: (context, i) {
          return DeviceCard(devInfo: _devList[i]);
        });
  }

  @override
  void onConnected(DevInfo info) {
    _devList.add(info);
    setState(() {});
  }

  @override
  void onDisConnected(String devId) {
    _devList.removeWhere((dev) => dev.guid == devId);
    setState(() {});
  }
}
