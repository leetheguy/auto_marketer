import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../editor/editor_screen.dart';
import 'list_provider.dart';

class ListScreen extends ConsumerWidget {
  const ListScreen({
    super.key,
    required this.contentType,
  });

  final ContentType contentType;

  String get _title {
    switch (contentType) {
      case ContentType.article:
        return 'Articles';
      case ContentType.idea:
        return 'Ideas';
      case ContentType.task:
        return 'Tasks';
    }
  }

  String get _createWebhookCommand {
    switch (contentType) {
      case ContentType.article:
        return 'create-article';
      case ContentType.idea:
        return 'create-idea';
      case ContentType.task:
        return ''; // No command for tasks yet
    }
  }

  IconData get _icon {
    switch (contentType) {
      case ContentType.article:
        return Icons.article_outlined;
      case ContentType.idea:
        return Icons.lightbulb_outline;
      case ContentType.task:
        return Icons.task_alt;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsyncValue = ref.watch(listProvider(contentType));

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
      ),
      body: listAsyncValue.when(
        data: (items) => ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card( // Using a Card for elevation and margin
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(_icon),
                title: Text(item.title),
                subtitle: Text(item.subtitle),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EditorScreen(contentItemId: item.contentItemId),
                    ),
                  );
                },
              ),
            );
          },
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _createNewItem(context, ref),
      ),
    );
  }

  Future<void> _createNewItem(BuildContext context, WidgetRef ref) async {
    final command = _createWebhookCommand;
    if (command.isEmpty) return; // Do nothing if no command is set

    final url = Uri.parse(AppConfig.getWebhookUrl(command));
    try {
      final response = await http.post(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final String contentItemId = responseData['content_item_id'];
        
        // Invalidate the provider to refresh the list
        ref.invalidate(listProvider(contentType));

        if (context.mounted) {
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
