import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/list_screen.dart';
import 'nav_button.dart';
import '../workflow/workflow_provider.dart'; // Import the new central provider

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the new central workflowProvider
    final workflowAsyncValue = ref.watch(workflowProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Marketer'),
      ),
      body: workflowAsyncValue.when(
        // We get the fully parsed Workflow object here
        data: (workflow) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            // The types are now directly on the workflow object
            itemCount: workflow.types.length,
            itemBuilder: (context, index) {
              final type = workflow.types[index];
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
      // We will refactor the FAB later to be driven by the workflow
      // floatingActionButton: ...
    );
  }
}
