import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../workflow/workflow_models.dart';
import '../workflow/workflow_provider.dart';
import '../config.dart';

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

// A "family" StreamProvider that provides a real-time stream of content lists.
final listProvider = StreamProvider.family<List<ListItem>, ListProviderParams>((ref, params) {
  final controller = StreamController<List<ListItem>>();

  Future<void> fetchList() async {
    // Await the workflow data directly from the main async provider.
    final workflowData = await ref.read(workflowProvider.future);
    final workflow = workflowData.workflow;

    String rpcName;
    Map<String, dynamic> rpcParams;

    if (params.parentId != null) {
      rpcName = 'get_child_content_items';
      rpcParams = {'p_parent_id': params.parentId};
    } else if (params.typeName != null) {
      rpcName = 'get_content_items_by_type';
      rpcParams = {'p_type_name': params.typeName};
    } else {
      controller.addError(ArgumentError('ListProvider requires either a typeName or a parentId.'));
      return;
    }

    try {
      final response = await supabase.rpc(rpcName, params: rpcParams);
      final items = (response as List).map((map) => ListItem.fromMap(map, workflow)).toList();
      if (!controller.isClosed) {
        controller.add(items);
      }
    } catch (e) {
      debugLog('Error fetching list: $e');
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }

  // Fetch the initial list.
  fetchList();

  // Subscribe to changes on the content_items table.
  final channel = supabase.channel('public:content_items');
  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'content_items',
    callback: (payload) {
      debugLog('Realtime update received for content_items. Refetching list.');
      fetchList();
    },
  ).subscribe();

  // When the provider is disposed, close the controller and unsubscribe.
  ref.onDispose(() {
    debugLog('Disposing listProvider and unsubscribing from channel.');
    supabase.removeChannel(channel);
    controller.close();
  });

  return controller.stream;
});
