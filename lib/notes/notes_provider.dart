import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart'; // To access the global supabase client

// 1. A simple data model for a Note.
class Note {
  Note({required this.id, required this.title, required this.content});

  final String id;
  final String title;
  final String content;

  // A factory to create a Note from the JSON map Supabase gives us.
  factory Note.fromJson(Map<String, dynamic> map) {
    return Note(
      id: map['id'].toString(),
      // UPDATED: Handle nulls from the database by providing a default empty string.
      title: map['title'] ?? '',
      content: map['content'] ?? '',
    );
  }
}

// 2. The StreamProvider that provides a real-time stream of notes.
final notesStreamProvider = StreamProvider<List<Note>>((ref) {
  final stream = supabase.from('notes').stream(primaryKey: ['id']);
  
  // For each event in the stream (a List of Maps), convert it to a List of Notes.
  return stream.map((maps) => maps.map((map) => Note.fromJson(map)).toList());
});