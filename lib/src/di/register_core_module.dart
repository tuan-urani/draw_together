import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:draw_together/src/core/repository/auth_repository.dart';
import 'package:draw_together/src/core/repository/profile_repository.dart';
import 'package:draw_together/src/core/repository/room_repository.dart';
import 'package:draw_together/src/core/repository/scoring_repository.dart';
import 'package:draw_together/src/core/repository/submission_repository.dart';
import 'package:draw_together/src/core/repository/target_repository.dart';
import 'package:draw_together/src/core/supabase/supabase_initializer.dart';

Future<void> registerCoreModule() async {
  await SupabaseInitializer.initialize();

  if (!Get.isRegistered<SupabaseClient>()) {
    Get.put<SupabaseClient>(Supabase.instance.client, permanent: true);
  }

  if (!Get.isRegistered<AuthRepository>()) {
    Get.put<AuthRepository>(
      AuthRepository(Get.find<SupabaseClient>()),
      permanent: true,
    );
  }

  if (!Get.isRegistered<RoomRepository>()) {
    Get.put<RoomRepository>(
      RoomRepository(Get.find<SupabaseClient>()),
      permanent: true,
    );
  }

  if (!Get.isRegistered<ProfileRepository>()) {
    Get.put<ProfileRepository>(
      ProfileRepository(Get.find<SupabaseClient>()),
      permanent: true,
    );
  }

  if (!Get.isRegistered<TargetRepository>()) {
    Get.put<TargetRepository>(
      TargetRepository(Get.find<SupabaseClient>()),
      permanent: true,
    );
  }

  if (!Get.isRegistered<SubmissionRepository>()) {
    Get.put<SubmissionRepository>(
      SubmissionRepository(Get.find<SupabaseClient>()),
      permanent: true,
    );
  }

  if (!Get.isRegistered<ScoringRepository>()) {
    Get.put<ScoringRepository>(
      ScoringRepository(Get.find<SupabaseClient>()),
      permanent: true,
    );
  }
}
