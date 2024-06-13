import 'package:flutter/material.dart';

class Loading extends StatelessWidget {
  final double width;
  final Widget? description;

  const Loading({
    super.key,
    this.width = 24,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: width,
            height: width,
            child: const CircularProgressIndicator(
              strokeWidth: 2.0,
            ),
          ),
          Visibility(
            visible: description != null,
            child: Container(
              margin: const EdgeInsets.only(top: 20),
              child: description,
            ),
          )
        ],
      ),
    );
  }
}
