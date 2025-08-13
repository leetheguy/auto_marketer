import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../workflow/workflow_models.dart';
import '../workflow/workflow_provider.dart';

// A simple data model for the current content item's data.
class ContentItemData {
  const ContentItemData({required this.typeName, required this.stateName});
  final String typeName;
  final String stateName;
}

// A provider to fetch the data for the current content item.
final currentContentItemProvider =
    FutureProvider.family<ContentItemData, String>((ref, contentItemId) async {
  final response = await supabase
      .from('content_items')
      .select('type_name, state_name')
      .eq('id', contentItemId)
      .single();

  return ContentItemData(
    typeName: response['type_name'] as String,
    stateName: response['state_name'] as String,
  );
});

// The actionsProvider is now a FutureProvider to correctly handle async dependencies.
final actionsProvider =
    FutureProvider.family<List<WorkflowAction>, String>((ref, contentItemId) async {
  // Await the results of our two async dependencies.
  final workflowData = await ref.watch(workflowProvider.future);
  final itemData = await ref.watch(currentContentItemProvider(contentItemId).future);

  // Correctly access the nested .workflow property before calling the helper method.
  return workflowData.workflow.getActionsFor(itemData.typeName, itemData.stateName);
});
