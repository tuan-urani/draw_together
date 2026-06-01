import 'package:supabase_flutter/supabase_flutter.dart';

class AppSupabase {
  AppSupabase._();

  static SupabaseClient get client => Supabase.instance.client;
}
