import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:draw_together/src/core/model/profile.dart';
import 'package:draw_together/src/core/repository/profile_repository.dart';
import 'package:draw_together/src/core/repository/room_repository.dart';
import 'package:draw_together/src/locale/translation_manager.dart';
import 'package:draw_together/src/ui/home/bloc/home_bloc.dart';
import 'package:draw_together/src/ui/home/home_page.dart';

void main() {
  testWidgets('edit name dialog closes without disposed controller errors', (
    tester,
  ) async {
    Get.testMode = true;
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    final client = SupabaseClient(
      'https://example.supabase.co',
      'anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    Get.put<HomeBloc>(
      HomeBloc(_FakeProfileRepository(client), RoomRepository(client)),
    );

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      if (Get.isRegistered<HomeBloc>()) {
        await Get.delete<HomeBloc>(force: true);
      }
      Get.reset();
    });

    await tester.pumpWidget(
      GetMaterialApp(
        translations: TranslationManager(),
        locale: TranslationManager.defaultLocale,
        fallbackLocale: TranslationManager.fallbackLocale,
        home: const HomePage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.takeException(),
      isNull,
      reason: 'Home must lay out cleanly.',
    );

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Edit Name'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'Dialog must open cleanly.');

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Name'), findsNothing);
    expect(
      tester.takeException(),
      isNull,
      reason: 'Dialog must finish closing cleanly.',
    );
  });
}

class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository(super.client);

  @override
  Future<Profile> ensureCurrentProfile({String? displayName}) async {
    return const Profile(id: 'profile-id', displayName: 'Player1');
  }
}
