import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import 'workflow_models.dart';

// A simple provider to hold the ID of the currently active workflow.
// For now, we'll hardcode it to 1.
final activeWorkflowIdProvider = StateProvider<int>((ref) => 1);

// The central provider that fetches, parses, and provides the active workflow.
final workflowProvider = FutureProvider<Workflow>((ref) async {
  final workflowId = ref.watch(activeWorkflowIdProvider);

  // Fetch the workflow definition from the database.
  final response = await supabase
      .from('workflows')
      .select('definition')
      .eq('id', workflowId)
      .single(); // Use .single() to get a single object, not a list.

  final definitionJson = response['definition'];

  // Parse the JSON into our structured Workflow object.
  final workflow = Workflow.fromJson(definitionJson);

  return workflow;
});
