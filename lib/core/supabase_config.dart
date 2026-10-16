import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase project connection details and shared client access.
///
/// The anon/public key below is safe to ship inside a client app — it only
/// grants what the database's Row Level Security policies allow.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://wmspoyslgcnepitxnphv.supabase.co';
  static const String publishableKey =
      'sb_publishable_JAj0zgP8p0sg0MAw-oHGSg_AsEciNV0';

  static Future<void> initialize() {
    return Supabase.initialize(url: url, publishableKey: publishableKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
