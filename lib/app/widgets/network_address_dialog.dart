import 'dart:io';

import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NetworkAddressDialog extends StatelessWidget {
  List<NetworkInterface> interfaces;

  NetworkAddressDialog({super.key, required this.interfaces});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(TranslationKey.localIpAddress.tr),
      content: SingleChildScrollView(
        child: ListBody(
          children: interfaces.map((interface) {
            final addresses = interface.addresses
                .where((itf) => itf.type == InternetAddressType.IPv4);
            if (addresses.isEmpty) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  interface.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
                ...addresses.map((address) {
                  return Text(address.address);
                }),
              ],
            );
          }).toList(),
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                Get.back();
              },
              child: Text(TranslationKey.dialogConfirmText.tr),
            ),
          ],
        )
      ],
    );
  }
}
