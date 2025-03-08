import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:flutter/material.dart';

class EmptyContent extends StatelessWidget {
  String? description;
  double size;
  bool showText;

  EmptyContent({
    super.key,
    this.description,
    this.size = 100,
    this.showText = true,
  }) {
    description = description ?? TranslationKey.emptyData.tr;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: Image.asset(
            'assets/images/empty.png',
            width: size,
            height: size,
          ),
        ),
        if (showText)
          Text(
            description!,
            style: const TextStyle(color: Colors.grey),
          ),
      ],
    );
  }
}
