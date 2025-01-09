import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:flutter/material.dart';

class EmptyContent extends StatelessWidget {
  String? description;

  EmptyContent({super.key, this.description}) {
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
            width: 100,
            height: 100,
          ),
        ),
        Text(
          description!,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
