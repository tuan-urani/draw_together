import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnvironment {
  AppEnvironment._();

  static String get apiBaseUrl => _required('API_BASE_URL');

  static String get supabaseUrl => _required('SUPABASE_URL');

  static String get supabasePublishableKey =>
      _required('SUPABASE_PUBLISHABLE_KEY');

  static String _required(String key) {
    final value = dotenv.env[key]?.trim();
    if (value == null || value.isEmpty) {
      throw StateError('Missing environment variable: $key');
    }
    return value;
  }
}
