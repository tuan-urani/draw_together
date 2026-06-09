import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:draw_together/src/core/audio/app_audio_manager.dart';

class AppAudioTap {
  AppAudioTap._();

  static VoidCallback? wrap(VoidCallback? onTap) {
    if (onTap == null) return null;

    return () {
      _play();
      onTap();
    };
  }

  static void play() {
    _play();
  }

  static void _play() {
    if (!Get.isRegistered<AppAudioManager>()) return;
    Get.find<AppAudioManager>().playButtonTap();
  }
}
