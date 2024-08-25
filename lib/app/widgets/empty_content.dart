import 'package:flutter/material.dart';

class EmptyContent extends StatelessWidget {
  final String description;

  const EmptyContent({super.key, this.description = "无数据"});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: Image.asset(
            'assets/images/empty.png',
            width: 100,
            height: 100,
          ),
        ),
        Text(
          description,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
