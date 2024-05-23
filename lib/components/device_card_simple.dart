import 'package:clipshare/components/rounded_chip.dart';
import 'package:clipshare/entity/tables/device.dart';
import 'package:clipshare/util/constants.dart';
import 'package:flutter/material.dart';

class DeviceCardSimple extends StatelessWidget {
  final Device dev;
  final void Function() onTap;

  const DeviceCardSimple({
    super.key,
    required this.dev,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const chipColor = Color.fromARGB(255, 213, 222, 232);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        mouseCursor: SystemMouseCursors.basic,
        onTap: () {
          onTap.call();
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Constants.devTypeIcons[dev.type] ??
                    const Icon(Icons.device_unknown),
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            dev.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Row(
                        children: [
                          RoundedChip(
                            label: Text(dev.type),
                            backgroundColor: chipColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
