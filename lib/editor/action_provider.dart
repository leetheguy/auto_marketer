import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../workflow/workflow_models.dart';
import '../workflow/workflow_provider.dart';

// This provider now simply reads the central workflow and the current content item's state
// to determine the available actions.
final actionsProvider = FutureProvider.family<List<WorkflowAction>, String>((ref, contentItemId) async {
  // Get the fully parsed workflow definition.
  final workflow = await ref.watch(workflowProvider.future);

  // Fetch the specific content item to know its current type and state.
  final contentItemResponse = await supabase
      .from('content_items')
      .select('type_name, state_name')
      .eq('id', contentItemId)
      .single();

  final typeName = contentItemResponse['type_name'] as String;
  final stateName = contentItemResponse['state_name'] as String;

  // Use the helper method on our Workflow object to get the actions.
  final actions = workflow.getActionsFor(typeName, stateName);

  return actions;
});
