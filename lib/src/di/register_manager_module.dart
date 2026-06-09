import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:draw_together/src/core/audio/app_audio_manager.dart';
import 'package:draw_together/src/utils/app_shared.dart';

Future<void> registerManagerModule() async {
  if (!Get.isRegistered<AppShared>()) {
    final sharedPreferences = await SharedPreferences.getInstance();
    Get.put<AppShared>(AppShared(sharedPreferences), permanent: true);
  }

  if (!Get.isRegistered<AppAudioManager>()) {
    final audioManager = AppAudioManager(Get.find<AppShared>());
    await audioManager.initialize();
    Get.put<AppAudioManager>(audioManager, permanent: true);
  }
}
