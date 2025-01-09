import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class RuleImportType extends StatelessWidget {
  final void Function() onUrlTypeClicked;
  final void Function() onLocalFileTypeClicked;

  const RuleImportType({
    super.key,
    required this.onUrlTypeClicked,
    required this.onLocalFileTypeClicked,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: IntrinsicHeight(
        child: Column(
          children: [
            ListTile(
              leading: Icon(MdiIcons.web),
              title: Text(TranslationKey.importFromNet.tr),
              onTap: onUrlTypeClicked,
            ),
            ListTile(
              leading: Icon(MdiIcons.fileDocumentOutline),
              title: Text(TranslationKey.importFromLocal.tr),
              onTap: onLocalFileTypeClicked,
            ),
          ],
        ),
      ),
    );
  }
}
