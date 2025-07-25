import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'notes_provider.dart';

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the provider. The UI will rebuild when the stream emits new data.
    final notesAsyncValue = ref.watch(notesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
      ),
      body: notesAsyncValue.when(
        // 2. Use the 'when' block to handle all states of the async data.
        data: (notes) => ListView.builder(
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return ListTile(
              title: Text(note.title),
              subtitle: Text(note.content),
            );
          },
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showCreateNoteDialog(context),
      ),
    );
  }

  // 3. A dialog to input new note data.
  void _showCreateNoteDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Note'),
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
              // 4. On save, send the data to the n8n webhook.
              _sendToN8n(titleController.text, contentController.text);
              Navigator.of(context).pop();
            },
          )
        ],
      ),
    );
  }

  // 5. The function that makes the HTTP POST request to n8n.
  Future<void> _sendToN8n(String title, String content) async {
    // final url = Uri.parse('https://n8n-service-eumn.onrender.com/webhook-test/note-creator');
    final url = Uri.parse('https://n8n-service-eumn.onrender.com/webhook/note-creator');
    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'title': title, 'content': content}),
    );
  }
}