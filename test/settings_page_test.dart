import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:draw_together/src/locale/translation_manager.dart';
import 'package:draw_together/src/ui/settings/settings_page.dart';
import 'package:draw_together/src/utils/app_pages.dart';

void main() {
  testWidgets('settings page renders audio and support sections', (
    tester,
  ) async {
    Get.testMode = true;
    await tester.binding.setSurfaceSize(const Size(390, 1000));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      Get.reset();
    });

    await tester.pumpWidget(
      GetMaterialApp(
        translations: TranslationManager(),
        locale: TranslationManager.defaultLocale,
        fallbackLocale: TranslationManager.fallbackLocale,
        home: const SettingsPage(),
      ),
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Audio'), findsOneWidget);
    expect(find.text('Background Music'), findsOneWidget);
    expect(find.text('Sound Effects'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    expect(find.text('Delete Account'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings support links open web view route with urls', (
    tester,
  ) async {
    Get.testMode = true;
    await tester.binding.setSurfaceSize(const Size(390, 1000));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      Get.reset();
    });

    await tester.pumpWidget(
      GetMaterialApp(
        translations: TranslationManager(),
        locale: TranslationManager.defaultLocale,
        fallbackLocale: TranslationManager.fallbackLocale,
        getPages: [
          GetPage(
            name: AppPages.settingsWebView,
            page: () => const _WebViewRouteProbe(),
          ),
        ],
        home: const SettingsPage(),
      ),
    );

    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(
      find.text('https://show.urani.tech/drawtogether/privacy-policy.html'),
      findsOneWidget,
    );

    Get.back<void>();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Terms of Use'));
    await tester.pumpAndSettle();
    expect(find.text('Terms of Use'), findsOneWidget);
    expect(
      find.text('https://show.urani.tech/drawtogether/terms-of-use.html'),
      findsOneWidget,
    );
  });
}

class _WebViewRouteProbe extends StatelessWidget {
  const _WebViewRouteProbe();

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<dynamic, dynamic>;

    return Scaffold(
      body: Column(
        children: [Text(args['title'] as String), Text(args['url'] as String)],
      ),
    );
  }
}
