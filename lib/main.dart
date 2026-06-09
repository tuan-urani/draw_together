import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:draw_together/src/di/register_manager_module.dart';
import 'package:draw_together/src/locale/translation_manager.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:draw_together/src/utils/app_pages.dart';
import 'package:draw_together/src/utils/app_shared.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  widgetsBinding.deferFirstFrame();
  await registerManagerModule();

  final savedLanguageCode = Get.find<AppShared>().getLanguageCode();
  final deviceLanguageCode =
      widgetsBinding.platformDispatcher.locale.languageCode;
  final initialLocale = TranslationManager.resolveLocale(
    savedLanguageCode ?? deviceLanguageCode,
  );

  runApp(App(initialLocale: initialLocale));
}

class App extends StatelessWidget {
  const App({this.initialLocale = TranslationManager.defaultLocale, super.key});

  final Locale initialLocale;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: AppColors.colorF7FBFF),
      initialRoute: AppPages.splash,
      getPages: AppPages.pages,
      translations: TranslationManager(),
      locale: initialLocale,
      fallbackLocale: TranslationManager.fallbackLocale,
    );
  }
}
