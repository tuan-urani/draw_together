import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:draw_together/src/core/config/app_environment.dart';

class SupabaseInitializer {
  SupabaseInitializer._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    await Supabase.initialize(
      url: AppEnvironment.supabaseUrl,
      anonKey: AppEnvironment.supabasePublishableKey,
    );

    _initialized = true;
  }
}
