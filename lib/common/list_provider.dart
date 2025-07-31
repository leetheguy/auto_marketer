import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';

// An enum to define our content types in a type-safe way.
enum ContentType {
  article,
  idea,
  task,
}

// A generic view model for any item that can appear in a list.
class ListItem {
  ListItem({
    required this.id,
    required this.contentItemId,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String contentItemId;
  final String title;
  final String subtitle;

  factory ListItem.fromMap(Map<String, dynamic> map) {
    return ListItem(
      id: map['item_id'] as String,
      contentItemId: map['content_item_id'] as String,
      title: map['title'] ?? 'Untitled',
      subtitle: map['subtitle'] ?? '',
    );
  }
}

// A "family" provider that can fetch different types of content.
final listProvider = FutureProvider.family<List<ListItem>, ContentType>((ref, contentType) async {
  String rpcName;

  // Choose the correct database function based on the content type.
  switch (contentType) {
    case ContentType.article:
      rpcName = 'get_articles_with_latest_text';
      break;
    case ContentType.idea:
      rpcName = 'get_ideas_with_latest_text';
      break;
    case ContentType.task:
      // We'll add the function for tasks later.
      // For now, return an empty list to prevent errors.
      return [];
  }

  final response = await supabase.rpc(rpcName);

  final items = (response as List).map((map) {
    return ListItem.fromMap(map);
  }).toList();

  return items;
});
