import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import 'workflow_models.dart';

// A new class to hold both the workflow's ID and its definition.
class WorkflowData {
  const WorkflowData({required this.id, required this.workflow});
  final int id;
  final Workflow workflow;
}

// Provider to hold the list of available accounts.
final accountsProvider = FutureProvider<Map<int, String>>((ref) async {
  final response = await supabase.from('accounts').select('id, name');
  return {for (var item in response) item['id'] as int: item['name'] as String};
});

// Provider to hold the ID of the currently selected account.
final selectedAccountIdProvider = StateProvider<int?>((ref) => null);

// The central provider now fetches and returns the full WorkflowData object.
final workflowProvider = FutureProvider<WorkflowData>((ref) async {
  final accountId = ref.watch(selectedAccountIdProvider);

  if (accountId == null) {
    // Return an empty/default state if no account is selected.
    return WorkflowData(
      id: -1, // Use an invalid ID
      workflow: Workflow.fromJson({"workflow": {"types": []}}),
    );
  }

  // Fetch the workflow's ID and definition for the selected account.
  final response = await supabase
      .from('workflows')
      .select('id, definition')
      .eq('account_id', accountId)
      .single();

  final definitionJson = response['definition'];
  final workflowId = response['id'] as int;
  final workflow = Workflow.fromJson(definitionJson);

  return WorkflowData(id: workflowId, workflow: workflow);
});
