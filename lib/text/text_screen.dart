// lib/text/text_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'text_provider.dart'; // We'll rename this file later
import '../config.dart';
import '../editor/editor_screen.dart';

class TextScreen extends ConsumerWidget {
  const TextScreen({super.key});
  
  Future<void> _createNewArticle(BuildContext context, WidgetRef ref) async {
    final url = Uri.parse(AppConfig.getWebhookUrl('create-article'));
    try {
      final response = await http.post(url);
      debugLog('N8N RAW RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        // --- FINAL, CORRECTED PARSING ---

        // The response is a single object, so we decode directly to a Map.
        final Map<String, dynamic> articleData = json.decode(response.body);

        // Now we can access the ID directly from the map.
        final String contentItemId = articleData['content_item_id'];
        debugLog('New content item created with ID: $contentItemId');

        // --- END OF PARSING LOGIC ---

        ref.invalidate(articlesProvider);

        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EditorScreen(contentItemId: contentItemId),
            ),
          );
        }
      } else {
        debugLog('Failed to create article. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugLog('Error calling create-article webhook: $e');
    }
  }




  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // UPDATED: Watch the new articlesProvider
    final articlesAsyncValue = ref.watch(articlesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Articles'), // Updated title
      ),
      // UPDATED: Use the new variable
      body: articlesAsyncValue.when(
        data: (articles) => ListView.builder(
          itemCount: articles.length,
          itemBuilder: (context, index) {
            final article = articles[index];
            return ListTile(
              title: Text(article.title),
              subtitle: Text(article.subtitle),
              leading: const Icon(Icons.article_outlined),
              onTap: () { // <-- ADD THIS onTap HANDLER
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EditorScreen(contentItemId: article.contentItemId),
                  ),
                );
              },
            );
          },
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _createNewArticle(context, ref), // <-- UPDATED
      ),
    );
  }

  // The _showCreateTextDialog and _sendToN8n methods are now outdated.
  // We can leave them here for a moment, but we will replace them.
}