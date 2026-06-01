import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:draw_together/src/di/di_graph_setup.dart';
import 'package:draw_together/src/locale/translation_manager.dart';
import 'package:draw_together/src/utils/app_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependenciesGraph();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.splash,
      getPages: AppPages.pages,
      translations: TranslationManager(),
      locale: TranslationManager.defaultLocale,
      fallbackLocale: TranslationManager.fallbackLocale,
    );
  }
}
