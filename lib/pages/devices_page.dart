import 'package:clipshare/entity/dev_info.dart';
import 'package:flutter/material.dart';

import '../components/device_card.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  @override
  Widget build(BuildContext context) {
    return DeviceCard(devInfo: DevInfo("", "", ""));
  }
}
