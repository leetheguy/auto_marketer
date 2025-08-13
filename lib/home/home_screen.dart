import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../common/list_provider.dart';
import '../common/list_screen.dart';
import '../config.dart';
import '../editor/editor_screen.dart';
import 'nav_button.dart';
import '../workflow/workflow_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflowAsyncValue = ref.watch(workflowProvider);
    final accountsAsyncValue = ref.watch(accountsProvider);
    final selectedAccountId = ref.watch(selectedAccountIdProvider);

    // Set the first account as the default selection when the app loads.
    ref.listen(accountsProvider, (_, next) {
      if (next.hasValue && next.value!.isNotEmpty && selectedAccountId == null) {
        ref.read(selectedAccountIdProvider.notifier).state = next.value!.keys.first;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Marketer'),
        actions: [
          // Account selection dropdown
          accountsAsyncValue.when(
            data: (accounts) => DropdownButton<int>(
              value: selectedAccountId,
              onChanged: (value) {
                ref.read(selectedAccountIdProvider.notifier).state = value;
              },
              items: accounts.entries.map((entry) {
                return DropdownMenuItem<int>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, s) => const Icon(Icons.error),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: workflowAsyncValue.when(
        data: (workflowData) => Padding( // Now receives WorkflowData
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: workflowData.workflow.types.length, // Access workflow property
            itemBuilder: (context, index) {
              final type = workflowData.workflow.types[index]; // Access workflow property
              return HomeNavButton(
                icon: type.icon,
                label: type.name,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ListScreen(typeName: type.name),
                    ),
                  );
                },
              );
            },
          ),
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.lightbulb_outline),
        label: const Text('New Idea'),
        onPressed: () => _createNewIdea(context, ref),
      ),
    );
  }

  // This method now correctly gets the workflowId from the provider.
  Future<void> _createNewIdea(BuildContext context, WidgetRef ref) async {
    const command = 'create-idea';
    final url = Uri.parse(AppConfig.getWebhookUrl(command));
    print(url);
    try {
      // Pass the selected account and workflow info to n8n
      final accountId = ref.read(selectedAccountIdProvider);
      final workflowData = await ref.read(workflowProvider.future);
      final workflowId = workflowData.id;

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'account_id': accountId,
          'workflow_id': workflowId,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final String contentItemId = responseData['content_item_id'];
        
        // Invalidate the 'Idea' list so it's fresh.
        ref.invalidate(listProvider(const ListProviderParams(typeName: 'Idea')));

        if (context.mounted) {
          // 1. Push the Ideas list screen onto the stack.
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ListScreen(typeName: 'Idea'),
            ),
          );
          // 2. Immediately push the Editor screen on top of the list screen.
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EditorScreen(contentItemId: contentItemId),
            ),
          );
        }
      } else {
        debugLog('Failed to create item. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugLog('Error calling create webhook: $e');
    }
  }
}
