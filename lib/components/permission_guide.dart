import 'package:flutter/material.dart';

class PermissionGuide extends StatelessWidget {
  final IconData icon;
  final String description;
  final String title;
  final void Function()? grantPerm;

  const PermissionGuide({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.grantPerm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        const SizedBox(
          height: 20,
        ),
        Icon(
          icon,
          size: 60,
          color: Colors.blueAccent,
        ),
        const SizedBox(
          height: 20,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 12),
          child: Text(description),
        ),
        grantPerm == null
            ? const SizedBox.shrink()
            : const SizedBox(
                height: 30,
              ),
        grantPerm == null
            ? const SizedBox.shrink()
            : TextButton(
                onPressed: () {
                  grantPerm!.call();
                },
                child: const Text("去授权"),
              ),
      ],
    );
  }
}
