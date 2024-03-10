import 'package:clipshare/components/setting_card.dart';
import 'package:clipshare/components/setting_header.dart';
import 'package:flutter/cupertino.dart';

class SettingCardGroup extends StatelessWidget {
  final String groupName;
  final Icon icon;
  final List<SettingCard> cardList;
  final double radius;

  const SettingCardGroup({
    super.key,
    required this.groupName,
    required this.icon,
    required this.cardList,
    this.radius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    var topBorder = BorderRadius.only(
      topLeft: Radius.circular(radius),
      topRight: Radius.circular(radius),
    );
    var bottomBorder = BorderRadius.only(
      bottomLeft: Radius.circular(radius),
      bottomRight: Radius.circular(radius),
    );
    var allBorder = BorderRadius.all(Radius.circular(radius));
    var empty = cardList.where((card) => card.show?.call() != false).isEmpty;
    return empty
        ? const SizedBox.shrink()
        : Column(
            children: [
              SettingHeader(title: groupName, icon: icon),
              for (var i = 0; i < cardList.length; i++)
                cardList[i]
                  ..borderRadius = cardList.length == 1
                      ? allBorder
                      : (i == 0
                          ? topBorder
                          : i == cardList.length - 1
                              ? bottomBorder
                              : BorderRadius.zero),
            ],
          );
  }
}
