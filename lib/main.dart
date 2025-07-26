import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'text/text_screen.dart';
import 'config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize our config first. This loads the .env file.
  await AppConfig.initialize();

  // Now we can safely use the config variables
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// ... MyApp class and supabase global variable remain the same

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thin Client App',
      theme: ThemeData.dark(useMaterial3: true),
      home: const TextScreen(),
    );
  }
}

final supabase = Supabase.instance.client;