import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:flutter/material.dart';

class EmptyContent extends StatelessWidget {
  String? description;
  Color? descriptionTextColor;
  Widget? icon;
  double size;
  bool showText;

  EmptyContent({
    super.key,
    this.icon,
    this.description,
    this.descriptionTextColor,
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
          child: icon ??
              Image.asset(
                'assets/images/empty.png',
                width: size,
                height: size,
              ),
        ),
        if (showText)
          Text(
            description!,
            style: TextStyle(color: descriptionTextColor ?? Colors.grey),
          ),
      ],
    );
  }
}
