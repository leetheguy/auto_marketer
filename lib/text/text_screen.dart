// lib/text/text_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'text_provider.dart'; // Updated import

// Renamed from NotesScreen to TextScreen
class TextScreen extends ConsumerWidget {
  const TextScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Updated provider
    final textAsyncValue = ref.watch(textStreamProvider); 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Text Items'), // Updated title
      ),
      body: textAsyncValue.when(
        data: (textItems) => ListView.builder( // Renamed variable
          itemCount: textItems.length,
          itemBuilder: (context, index) {
            final textItem = textItems[index]; // Renamed variable
            return ListTile(
              title: Text(textItem.title),
              subtitle: Text(textItem.content),
            );
          },
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showCreateTextDialog(context), // Renamed method
      ),
    );
  }

  void _showCreateTextDialog(BuildContext context) { // Renamed method
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Text Item'), // Updated title
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: contentController, decoration: const InputDecoration(labelText: 'Content')),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Save'),
            onPressed: () {
              _sendToN8n(titleController.text, contentController.text);
              Navigator.of(context).pop();
            },
          )
        ],
      ),
    );
  }

  Future<void> _sendToN8n(String title, String content) async {
    // Note: You may want to update this webhook path in n8n for consistency
    final url = Uri.parse('https://n8n-service-eumn.onrender.com/webhook-test/note-creator');
    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'title': title, 'content': content}),
    );
  }
}