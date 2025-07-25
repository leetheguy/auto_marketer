import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// UNCOMMENTED: Import the screen we just built.
import 'notes/notes_screen.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    // Ensure these are your actual Supabase URL and anon key.
    url: 'https://ibbwohrcuxvugizaiodp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImliYndvaHJjdXh2dWdpemFpb2RwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIzMjA2OTUsImV4cCI6MjA2Nzg5NjY5NX0.wVVW88M2s7AtIfajZCb6RMfdbCWVgzSn9RlxFpyx56k',
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
      title: 'Thin Client App',
      theme: ThemeData.dark(useMaterial3: true),
      // CHANGED: Set NotesScreen as the home screen.
      home: const NotesScreen(),
    );
  }
}

final supabase = Supabase.instance.client;