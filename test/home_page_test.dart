import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:draw_together/src/core/model/game_history_entry.dart';
import 'package:draw_together/src/core/model/game_room.dart';
import 'package:draw_together/src/core/model/game_round.dart';
import 'package:draw_together/src/core/model/profile.dart';
import 'package:draw_together/src/core/model/room_player.dart';
import 'package:draw_together/src/core/model/target_image.dart';
import 'package:draw_together/src/core/repository/history_repository.dart';
import 'package:draw_together/src/core/repository/profile_repository.dart';
import 'package:draw_together/src/core/repository/room_repository.dart';
import 'package:draw_together/src/locale/translation_manager.dart';
import 'package:draw_together/src/ui/home/bloc/home_bloc.dart';
import 'package:draw_together/src/ui/home/home_page.dart';
import 'package:draw_together/src/ui/settings/settings_page.dart';
import 'package:draw_together/src/utils/app_pages.dart';
import 'package:draw_together/src/utils/app_shared.dart';

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
      HomeBloc(
        _FakeProfileRepository(client),
        RoomRepository(client),
        _FakeHistoryRepository(client),
      ),
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
        getPages: [
          GetPage(name: AppPages.history, page: () => const _HistoryProbe()),
        ],
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

  testWidgets('recent games shows empty state and routes to history', (
    tester,
  ) async {
    Get.testMode = true;
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    final client = SupabaseClient(
      'https://example.supabase.co',
      'anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final historyRepository = _FakeHistoryRepository(client);
    Get.put<HomeBloc>(
      HomeBloc(
        _FakeProfileRepository(client),
        RoomRepository(client),
        historyRepository,
      ),
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
        getPages: [
          GetPage(name: AppPages.history, page: () => const _HistoryProbe()),
        ],
        home: const HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.history_rounded), findsNothing);
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    expect(find.text('Recent Games'), findsOneWidget);
    expect(find.text('Your gallery is empty'), findsOneWidget);
    expect(find.text('View All'), findsNothing);
    expect(historyRepository.requestedLimit, 3);

    await tester.tap(find.text('Recent Games'));
    await tester.pumpAndSettle();

    expect(find.text('History route'), findsOneWidget);
  });

  testWidgets('recent games renders history entries instead of dummy data', (
    tester,
  ) async {
    Get.testMode = true;
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    final client = SupabaseClient(
      'https://example.supabase.co',
      'anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final historyRepository = _FakeHistoryRepository(client, [
      _historyEntry('Rainbow Rocket'),
    ]);
    Get.put<HomeBloc>(
      HomeBloc(
        _FakeProfileRepository(client),
        RoomRepository(client),
        historyRepository,
      ),
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
        getPages: [
          GetPage(name: AppPages.history, page: () => const _HistoryProbe()),
        ],
        home: const HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rainbow Rocket'), findsOneWidget);
    expect(find.text('Fun Cats!'), findsNothing);
    expect(find.text('View All'), findsOneWidget);
    expect(historyRepository.requestedLimit, 3);
  });

  testWidgets('recent games refreshes after returning from a match flow', (
    tester,
  ) async {
    Get.testMode = true;
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    final client = SupabaseClient(
      'https://example.supabase.co',
      'anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final historyRepository = _FakeHistoryRepository(client);
    Get.put<HomeBloc>(
      HomeBloc(
        _FakeProfileRepository(client),
        RoomRepository(client),
        historyRepository,
      ),
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
        getPages: [
          GetPage(
            name: AppPages.roomBrowser,
            page: () => _RoomBrowserProbe(
              onFinish: () {
                historyRepository.entries = [_historyEntry('Fresh Match')];
              },
            ),
          ),
        ],
        home: const HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your gallery is empty'), findsOneWidget);

    await tester.tap(find.text('Co-op'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish match'));
    await tester.pumpAndSettle();

    expect(find.text('Fresh Match'), findsOneWidget);
    expect(historyRepository.loadCount, 2);
  });

  testWidgets('language change in settings updates home after back', (
    tester,
  ) async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final appShared = AppShared(preferences);
    final client = SupabaseClient(
      'https://example.supabase.co',
      'anon-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    Get
      ..put<AppShared>(appShared)
      ..put<HomeBloc>(
        HomeBloc(
          _FakeProfileRepository(client),
          RoomRepository(client),
          _FakeHistoryRepository(client),
        ),
      );
    await tester.binding.setSurfaceSize(const Size(390, 1000));

    addTearDown(() async {
      appShared.dispose();
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
        getPages: [
          GetPage(name: AppPages.settings, page: () => const SettingsPage()),
          GetPage(name: AppPages.history, page: () => const _HistoryProbe()),
        ],
        home: const HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recent Games'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Japanese').last);
    await tester.pumpAndSettle();

    expect(appShared.getLanguageCode(), 'ja');
    Get.back<void>();
    await tester.pumpAndSettle();

    expect(find.text('最近のゲーム'), findsOneWidget);
    expect(find.text('Recent Games'), findsNothing);
  });
}

class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository(super.client);

  @override
  Future<Profile> ensureCurrentProfile({String? displayName}) async {
    return const Profile(id: 'profile-id', displayName: 'Player1');
  }
}

class _FakeHistoryRepository extends HistoryRepository {
  _FakeHistoryRepository(super.client, [this.entries = const []]);

  List<GameHistoryEntry> entries;
  int? requestedLimit;
  int loadCount = 0;

  @override
  Future<List<GameHistoryEntry>> listHistory({int? limit}) async {
    loadCount += 1;
    requestedLimit = limit;
    return entries.take(limit ?? entries.length).toList(growable: false);
  }
}

GameHistoryEntry _historyEntry(String title) {
  final createdAt = DateTime(2026, 6, 9, 10);
  return GameHistoryEntry(
    room: GameRoom(
      id: 'room-id',
      code: 'ABC123',
      mode: RoomMode.coop,
      hostUserId: 'profile-id',
      status: RoomStatus.finished,
      maxPlayers: 2,
      createdAt: createdAt,
      expiresAt: createdAt.add(const Duration(hours: 1)),
    ),
    round: GameRound(
      id: 'round-id',
      roomId: 'room-id',
      mode: RoomMode.coop,
      targetImageId: 'target-id',
      status: RoundStatus.scored,
      durationMs: 60000,
      createdAt: createdAt,
      updatedAt: createdAt,
    ),
    target: TargetImage(
      id: 'target-id',
      storagePath: 'targets/rainbow.png',
      title: title,
      mode: RoomMode.coop,
      difficulty: TargetDifficulty.easy,
      width: 1024,
      height: 1024,
      mimeType: 'image/png',
      active: true,
      createdAt: createdAt,
    ),
    targetUrl: 'https://example.com/rainbow.png',
    submissions: const [],
    scores: const [],
    players: [
      RoomPlayer(
        roomId: 'room-id',
        userId: 'profile-id',
        seat: 1,
        joinedAt: createdAt,
        displayName: 'Player1',
      ),
      RoomPlayer(
        roomId: 'room-id',
        userId: 'friend-id',
        seat: 2,
        joinedAt: createdAt,
        displayName: 'Alice',
      ),
    ],
    currentUserId: 'profile-id',
  );
}

class _HistoryProbe extends StatelessWidget {
  const _HistoryProbe();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('History route'));
  }
}

class _RoomBrowserProbe extends StatelessWidget {
  const _RoomBrowserProbe({required this.onFinish});

  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () {
            onFinish();
            Get.back<void>();
          },
          child: const Text('Finish match'),
        ),
      ),
    );
  }
}
