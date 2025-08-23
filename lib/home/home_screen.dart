import 'package:auto_marketer/config.dart';
import 'package:auto_marketer/editor/editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../list/list_screen.dart';
import 'nav_button.dart';
import '../workflow/workflow_provider.dart';
import '../services/action_service.dart';


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
        data: (workflowData) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: workflowData.workflow.types.length,
            itemBuilder: (context, index) {
              final type = workflowData.workflow.types[index];
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

  // This method is now simpler and relies on the reactive StreamProvider.
  Future<void> _createNewIdea(BuildContext context, WidgetRef ref) async {
    final actionService = ref.read(actionServiceProvider);
    final accountId = ref.read(selectedAccountIdProvider);
    final workflowData = await ref.read(workflowProvider.future);
    final workflowId = workflowData.id;

    final response = await actionService.createNewIdea(
      accountId: accountId!,
      workflowId: workflowId
    );

    consoleInfo(response);

    if (response != null) {
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ListScreen(typeName: 'Idea'),
          ),
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EditorScreen(contentItemId: response),
          ),
        );
      }
    } else {
      consoleInfo('Failed to create new idea.');
    }


    //   if (context.mounted) {
    //     Navigator.of(context).push(
    //       MaterialPageRoute(
    //         builder: (context) => const ListScreen(typeName: 'Idea'),
    //       ),
    //     );
    //     Navigator.of(context).push(
    //       MaterialPageRoute(
    //         builder: (context) => EditorScreen(contentItemId: contentItemId),
    //       ),
    //     );
    //   }
    // } else {
    //   consoleInfo('Failed to create item. Status: ${response.statusCode}');
    // }
    
    // final actionService = ref.read(actionServiceProvider);


    // const command = 'create-idea';
    // final url = Uri.parse(AppConfig.getWebhookUrl(command));
    // try {
    //   final accountId = ref.read(selectedAccountIdProvider);
    //   final workflowData = await ref.read(workflowProvider.future);
    //   final workflowId = workflowData.id;

    //   final response = await http.post(
    //     url,
    //     headers: {'Content-Type': 'application/json'},
    //     body: json.encode({
    //       'account_id': accountId,
    //       'workflow_id': workflowId,
    //     }),
    //   );

    //   if (response.statusCode == 200) {
    //     final Map<String, dynamic> responseData = json.decode(response.body);
    //     final String contentItemId = responseData['content_item_id'];
        
    //     // The ref.invalidate call is no longer needed here.
    //     // The StreamProvider will handle updating the list automatically.

    //     if (context.mounted) {
    //       Navigator.of(context).push(
    //         MaterialPageRoute(
    //           builder: (context) => const ListScreen(typeName: 'Idea'),
    //         ),
    //       );
    //       Navigator.of(context).push(
    //         MaterialPageRoute(
    //           builder: (context) => EditorScreen(contentItemId: contentItemId),
    //         ),
    //       );
    //     }
    //   } else {
    //     consoleInfo('Failed to create item. Status: ${response.statusCode}');
    //   }
    // } catch (e) {
    //   consoleInfo('Error calling create webhook: $e');
    // }
  }
}
