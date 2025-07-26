// lib/text/text_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';

// 1. A simple model to match the data from our database function.
class ArticleListItem {
  ArticleListItem({
    required this.id,
    required this.contentItemId,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String contentItemId;
  final String title;
  final String subtitle;

  factory ArticleListItem.fromMap(Map<String, dynamic> map) {
    return ArticleListItem(
      id: map['article_id'] as String,
      contentItemId: map['content_item_id'] as String, 
      title: map['title'] ?? 'Untitled',
      subtitle: map['subtitle'] ?? '',
    );
  }
}

// 2. A FutureProvider that calls our new database function.
final articlesProvider = FutureProvider<List<ArticleListItem>>((ref) async {
  // Call the RPC and get the raw data
  final response = await supabase.rpc('get_articles_with_latest_text');

  // Convert the raw list of maps into a list of our typed ArticleListItem objects
  final items = (response as List).map((map) {
    return ArticleListItem.fromMap(map);
  }).toList();

  return items;
});