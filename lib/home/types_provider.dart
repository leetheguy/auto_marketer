import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';

// A simple data model for a content type.
class ContentTypeInfo {
  ContentTypeInfo({
    required this.id,
    required this.name,
    required this.icon,
  });

  final int id;
  final String name;
  final IconData icon;

  // A map to convert icon names from the DB to actual Flutter Icons.
  static const Map<String, IconData> _iconMap = {
    'folder_special_outlined': Icons.folder_special_outlined,
    'lightbulb_outline': Icons.lightbulb_outline,
    'article_outlined': Icons.article_outlined,
    'movie_outlined': Icons.movie_outlined,
    'campaign_outlined': Icons.campaign_outlined,
    'default': Icons.help_outline,
  };

  factory ContentTypeInfo.fromMap(Map<String, dynamic> map) {
    final iconName = map['icon_name'] as String? ?? 'default';
    return ContentTypeInfo(
      id: map['id'] as int,
      name: map['name'] as String,
      icon: _iconMap[iconName] ?? Icons.help_outline,
    );
  }
}

// A provider that fetches all available content types.
final typesProvider = FutureProvider<List<ContentTypeInfo>>((ref) async {
  final response = await supabase.from('types').select();
  
  final items = (response as List).map((map) {
    return ContentTypeInfo.fromMap(map);
  }).toList();

  return items;
});
