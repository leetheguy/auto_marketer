// lib/text/text_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';

// Renamed from Note to TextItem
class TextItem {
  TextItem({required this.id, required this.title, required this.content});

  final String id;
  final String title;
  final String content;

  factory TextItem.fromJson(Map<String, dynamic> map) {
    return TextItem(
      id: map['id'].toString(),
      title: map['title'] ?? '',
      content: map['content'] ?? '',
    );
  }
}

// Renamed from notesStreamProvider to textStreamProvider
// and updated to read from the 'text' table.
final textStreamProvider = StreamProvider<List<TextItem>>((ref) {
  final stream = supabase.from('text').stream(primaryKey: ['id']);
  return stream.map((maps) => maps.map((map) => TextItem.fromJson(map)).toList());
});