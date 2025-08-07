import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../common/list_provider.dart';
import '../common/list_screen.dart';
import '../config.dart';
import '../editor/editor_screen.dart';
import 'nav_button.dart';
import 'types_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsyncValue = ref.watch(typesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Marketer'),
      ),
      body: typesAsyncValue.when(
        data: (types) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: types.length,
            itemBuilder: (context, index) {
              final type = types[index];
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

  // This method now builds the correct navigation stack.
  Future<void> _createNewIdea(BuildContext context, WidgetRef ref) async {
    const command = 'create-idea';
    final url = Uri.parse(AppConfig.getWebhookUrl(command));
    try {
      final response = await http.post(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final String contentItemId = responseData['content_item_id'];
        
        // Invalidate the 'Idea' list so it's fresh when the user navigates back.
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
