import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';

// A map to convert icon names from the DB to actual Flutter Icons.
const Map<String, IconData> iconMap = {
  'folder_special_outlined': Icons.folder_special_outlined,
  'lightbulb_outline': Icons.lightbulb_outline,
  'article_outlined': Icons.article_outlined,
  'movie_outlined': Icons.movie_outlined,
  'campaign_outlined': Icons.campaign_outlined,
  'default': Icons.help_outline,
};

// A simple data model for any item that can appear in a list.
class ListItem {
  ListItem({
    required this.id,
    this.parentId,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.typeName, // Added typeName
  });

  final String id;
  final String? parentId;
  final String title;
  final String subtitle;
  final IconData icon;
  final String typeName; // Added typeName

  factory ListItem.fromMap(Map<String, dynamic> map) {
    final iconName = map['icon_name'] as String? ?? 'default';
    return ListItem(
      id: map['item_id'] as String,
      parentId: map['parent_id'] as String?,
      title: map['title'] ?? 'Untitled',
      subtitle: map['subtitle'] ?? '',
      icon: iconMap[iconName] ?? Icons.help_outline,
      typeName: map['type_name'] as String, // Added typeName
    );
  }
}

// A simple class to pass parameters to our new provider.
class ListProviderParams {
  const ListProviderParams({
    this.typeName,
    this.parentId,
  });

  final String? typeName;
  final String? parentId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ListProviderParams &&
        other.typeName == typeName &&
        other.parentId == parentId;
  }

  @override
  int get hashCode => typeName.hashCode ^ parentId.hashCode;
}

// A "family" provider that can fetch different types of content lists.
final listProvider = FutureProvider.family<List<ListItem>, ListProviderParams>((ref, params) async {
  
  String rpcName;
  Map<String, dynamic> rpcParams;

  if (params.parentId != null) {
    rpcName = 'get_child_content_items';
    rpcParams = {'p_parent_id': params.parentId};
  } else if (params.typeName != null) {
    rpcName = 'get_content_items_by_type';
    rpcParams = {'p_type_name': params.typeName};
  } else {
    throw ArgumentError('ListProvider requires either a typeName or a parentId.');
  }

  final response = await supabase.rpc(rpcName, params: rpcParams);

  final items = (response as List).map((map) {
    return ListItem.fromMap(map);
  }).toList();

  return items;
});
