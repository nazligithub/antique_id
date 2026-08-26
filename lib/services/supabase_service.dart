import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String _url = 'https://ycsuzygpkwpriomnwqec.supabase.co';
  static const String _anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inljc3V6eWdwa3dwcmlvbW53cWVjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDEyNTI3NDQsImV4cCI6MjA1NjgyODc0NH0.3eWjqrHS3yW00eblYUpDZ-yne5u8jm4MOrhy5yoY6S4';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
    );
  }

  // Get antique identifier app config
  static Future<Map<String, dynamic>?> getAntiqueIdentifierConfig() async {
    try {
      final response = await client
          .from('apps')
          .select('*')
          .eq('name', 'Antique Identifier')
          .single();

      debugPrint('Supabase config: $response');
      return response;
    } catch (e) {
      debugPrint('Error fetching config: $e');
      // Return default config when there's a network error
      return {'status': true}; // Default to showing yearly as monthly
    }
  }

  // Listen to real-time changes for antique identifier
  static Stream<Map<String, dynamic>?> listenToAntiqueIdentifierConfig() {
    try {
      return client
          .from('apps')
          .stream(primaryKey: ['id'])
          .eq('name', 'Antique Identifier')
          .map((data) {
            if (data.isNotEmpty) {
              debugPrint('Real-time config update: ${data.first}');
              return data.first as Map<String, dynamic>;
            }
            return null;
          })
          .handleError((error) {
            debugPrint('Real-time stream error: $error');
            // Return default config on error
            return {'status': true};
          });
    } catch (e) {
      debugPrint('Error setting up real-time listener: $e');
      // Return a stream that emits default config
      return Stream.value({'status': true});
    }
  }
}