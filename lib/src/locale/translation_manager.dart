import 'dart:ui';

import 'package:get/get.dart';

import 'lang_en.dart';
import 'lang_ja.dart';
import 'lang_vi.dart';

class TranslationManager extends Translations {
  static const Locale defaultLocale = Locale('en', 'US');
  static const Locale fallbackLocale = Locale('en', 'US');
  static const List<Locale> appLocales = <Locale>[
    Locale('en', 'US'),
    Locale('ja', 'JP'),
    Locale('vi', 'VN'),
  ];

  static Locale resolveLocale(String? languageCode) {
    return switch (languageCode?.toLowerCase()) {
      'ja' => const Locale('ja', 'JP'),
      'vi' => const Locale('vi', 'VN'),
      _ => defaultLocale,
    };
  }

  @override
  Map<String, Map<String, String>> get keys => <String, Map<String, String>>{
    'en_US': enUs,
    'ja_JP': jaJp,
    'vi_VN': viVn,
  };
}
