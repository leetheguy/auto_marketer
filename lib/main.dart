import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'home/home_screen.dart'; // Import the new home screen

// This is a global instance of the Supabase client
final supabase = Supabase.instance.client;

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto Marketer',
      theme: ThemeData.dark(useMaterial3: true),
      home: const HomeScreen(), // Set HomeScreen as the home page
    );
  }
}
