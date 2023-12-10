import 'package:clipshare/components/round_chip.dart';
import 'package:clipshare/entity/dev_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../main.dart';

class DeviceCard extends StatefulWidget {
  DevInfo devInfo;
  DeviceCard({super.key,required this.devInfo});

  @override
  State<StatefulWidget> createState() {
    return DeviceCardState();
  }
}

class DeviceCardState extends State<DeviceCard> {
  Map<String, Icon> typeIcons = const {
    'Windows': Icon(
      Icons.laptop_windows_outlined,
      color: Colors.grey,
      size: 48,
    ),
    'Android': Icon(
      Icons.phone_android_outlined,
      color: Colors.grey,
      size: 48,
    ),
    'IOS': Icon(
      Icons.apple_outlined,
      color: Colors.grey,
      size: 48,
    ),
    'Mac': Icon(
      Icons.laptop_mac_outlined,
      color: Colors.grey,
      size: 48,
    ),
    'Linux': Icon(
      Icons.laptop_windows_outlined,
      color: Colors.grey,
      size: 48,
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 72,
              child: Row(
                children: [
                  typeIcons[widget.devInfo.type] ??
                      const Icon(
                        Icons.network_check,
                        color: Colors.grey,
                        size: 48,
                      ),
                  Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.devInfo.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 22),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        RoundedChip(
                          label: Text(widget.devInfo.type),
                          backgroundColor: const Color.fromARGB(255, 213, 222, 232),
                        )
                      ],
                    ),
                  )
                ],
              ),
            )),
      ),
    );
  }
}
