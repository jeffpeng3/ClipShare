import 'package:flutter/material.dart';

class EmptyContent extends StatelessWidget {
  const EmptyContent({super.key});

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
        const Text("无数据",style: TextStyle(color: Colors.grey),),
      ],
    );
  }
}
