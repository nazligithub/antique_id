import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String _url = 'https://supabasekong-bw0skk4koc48go4444o8c8oo.mobinaz.work';
  static const String _anonKey =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsImlhdCI6MTc2MDc5NDYyMCwiZXhwIjo0OTE2NDY4MjIwLCJyb2xlIjoiYW5vbiJ9.1cYhfF0OU4tC3ICZnGn7pzNYDKzDTyv8Y5gGVTvxfwg';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(url: _url, anonKey: _anonKey);
  }
}
