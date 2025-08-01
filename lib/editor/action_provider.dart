import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../config.dart';

// A simple data model for an action state.
class ActionState {
  ActionState({
    required this.id,
    required this.label,
    required this.command,
  });

  final int id;
  final String label;
  final String command;

  factory ActionState.fromMap(Map<String, dynamic> map) {
    return ActionState(
      id: map['id'] as int,
      label: map['action_label'] as String,
      command: map['action_command'] as String,
    );
  }
}

// A "family" StreamProvider that provides a real-time stream of available actions
// for a specific content item.
final actionsProvider = StreamProvider.family<List<ActionState>, String>((ref, contentItemId) {
  final controller = StreamController<List<ActionState>>();

  Future<void> fetchActions() async {
    try {
      final response = await supabase.rpc(
        'get_item_states',
        params: {'p_content_item_id': contentItemId},
      );

      final items = (response as List)
          .where((map) => map['is_action'] == true)
          .map((map) => ActionState.fromMap(map))
          .toList();
      
      if (!controller.isClosed) {
        controller.add(items);
      }
    } catch (e) {
      debugLog('Error fetching actions: $e');
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }

  // Fetch the initial data.
  fetchActions();

  // Set up the Realtime subscription using the correct modern syntax.
  final channel = supabase.channel('item-states:$contentItemId');
  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'content_item_states',
    // Correctly construct the filter object.
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'content_item_id',
      value: contentItemId,
    ),
    callback: (payload) {
      debugLog('Realtime update received for item states. Refetching.');
      fetchActions();
    },
  ).subscribe();

  // When the provider is disposed, close the controller and unsubscribe from the channel.
  ref.onDispose(() {
    debugLog('Disposing actionsProvider and unsubscribing from channel.');
    supabase.removeChannel(channel);
    controller.close();
  });

  return controller.stream;
});
