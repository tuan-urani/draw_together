import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:draw_together/src/locale/translation_manager.dart';
import 'package:draw_together/src/utils/app_colors.dart';
import 'package:draw_together/src/utils/app_pages.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  widgetsBinding.deferFirstFrame();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: AppColors.colorF7FBFF),
      initialRoute: AppPages.splash,
      getPages: AppPages.pages,
      translations: TranslationManager(),
      locale: TranslationManager.defaultLocale,
      fallbackLocale: TranslationManager.fallbackLocale,
    );
  }
}
