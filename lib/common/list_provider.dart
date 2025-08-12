import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../workflow/workflow_models.dart';
import '../workflow/workflow_provider.dart';

// A simple data model for any item that can appear in a list.
class ListItem {
  ListItem({
    required this.id,
    this.parentId,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.typeName,
  });

  final String id;
  final String? parentId;
  final String title;
  final String subtitle;
  final IconData icon;
  final String typeName;

  factory ListItem.fromMap(Map<String, dynamic> map, Workflow workflow) {
    final typeName = map['type_name'] as String;
    // Find the type info from the central workflow to get the correct icon.
    final typeInfo = workflow.types.firstWhere(
      (t) => t.name == typeName,
      orElse: () => workflow.types.first, // Fallback
    );

    return ListItem(
      id: map['item_id'] as String,
      parentId: map['parent_id'] as String?,
      title: map['title'] ?? 'Untitled',
      subtitle: map['subtitle'] ?? '',
      icon: typeInfo.icon,
      typeName: typeName,
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
  final workflow = await ref.watch(workflowProvider.future);
  
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
    return ListItem.fromMap(map, workflow);
  }).toList();

  return items;
});
