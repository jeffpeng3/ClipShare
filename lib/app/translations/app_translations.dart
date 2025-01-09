import 'package:clipshare/app/data/enums/translation_key.dart';
import 'package:clipshare/app/translations/zh_cn_translations.dart';
import 'package:get/get.dart';

import 'en_us_translations.dart';
/**
 * GetX Template Generator - fb.com/htngu.99
 * */

class AppTranslation extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': EnUSTranslation().translations,
        'zh_CN': ZhCNTranslation().translations,
      };
}

abstract class AbstractTranslations {
  String translate(TranslationKey key);

  Map<String, String> get translations {
    const keys = TranslationKey.values;
    final map = <String, String>{};
    for (final key in keys) {
      final tr = translate(key);
      if (tr == key.name) {
        continue;
      }
      map[key.name] = tr;
    }
    return map;
  }
}
