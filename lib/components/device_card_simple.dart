import 'package:clipshare/components/rounded_chip.dart';
import 'package:clipshare/entity/tables/device.dart';
import 'package:clipshare/util/constants.dart';
import 'package:flutter/material.dart';

class DeviceCardSimple extends StatelessWidget {
  final Device dev;
  final bool showBorder;
  final void Function() onTap;

  const DeviceCardSimple({
    super.key,
    required this.dev,
    required this.onTap,
    this.showBorder = false,
  });

  static const borderWidth = 3.0;
  static const borderRadius = 12.0;

  @override
  Widget build(BuildContext context) {
    const chipColor = Color.fromARGB(255, 213, 222, 232);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        mouseCursor: SystemMouseCursors.basic,
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: () {
          onTap.call();
        },
        child: Container(
          margin: showBorder ? null : const EdgeInsets.all(borderWidth),
          decoration: showBorder
              ? BoxDecoration(
                  border: Border.all(
                    color: Colors.blue,
                    width: borderWidth,
                  ),
                  borderRadius: BorderRadius.circular(borderRadius),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Constants.devTypeIcons[dev.type] ??
                      const Icon(Icons.device_unknown),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Text(
                                    dev.name,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 22,
                                    ),
                                  ),
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
