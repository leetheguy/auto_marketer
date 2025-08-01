import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// A helper function for conditional printing that won't show warnings.
void debugLog(Object? message) {
  if (!kReleaseMode) {
    // ignore: avoid_print
    print(message);
  }
}


class AppConfig {
  // --- Secrets (loaded from .env) ---
  static late final String supabaseUrl;
  static late final String supabaseAnonKey;

  // --- Webhook Configuration ---
  
  // Manually set this to true to use test webhooks.
  static const bool useTestMode = false; 

  static const String _baseUrl = 'https://n8n-service-eumn.onrender.com';
  static const String _prodPath = 'webhook';
  static const String _testPath = 'webhook-test';

  // The single source of truth for all command names
  static const Set<String> webhookCommands = {
    'create-article',
    'create-idea',
    // 'archive-article',
  };

  
  // --- Initialization ---
  
  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");
    supabaseUrl = dotenv.env['SUPABASE_URL']!;
    supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;
  }
  
  // --- Methods ---
  
  static String getWebhookUrl(String command) {
    // This check ensures we don't try to build a URL for a non-existent command.
    assert(webhookCommands.contains(command), 'Unknown webhook command: $command');
    
    final path = useTestMode ? _testPath : _prodPath;
    return '$_baseUrl/$path/$command';
  }

  // --- App Behavior ---
  static const int editorDebounceMilliseconds = 500;
}
