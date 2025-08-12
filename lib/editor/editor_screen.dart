import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'action_provider.dart';
import 'editor_provider.dart';
import '../workflow/workflow_models.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({
    super.key,
    required this.contentItemId,
  });

  final String contentItemId;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
  
  Future<void> _executeAction(String command) async {
    final url = AppConfig.getWebhookUrl(command);
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'content_item_id': widget.contentItemId}),
      );
      if (response.statusCode == 200) {
        debugLog('Action $command executed successfully.');
        // Invalidate the provider to refetch the actions.
        ref.invalidate(actionsProvider(widget.contentItemId));
      } else {
        debugLog('Failed to execute action $command. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugLog('Error executing action $command: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorProvider(widget.contentItemId));
    final editorNotifier = ref.read(editorProvider(widget.contentItemId).notifier);

    ref.listen(editorProvider(widget.contentItemId), (_, next) {
      if (_titleController.text != next.title) {
        _titleController.text = next.title;
      }
      if (_contentController.text != next.content) {
        _contentController.text = next.content;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor'),
      ),
      body: editorState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildMenuBar(),
                const Divider(height: 1),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 700) {
                        return _buildWideLayout(editorNotifier);
                      } else {
                        return _buildNarrowLayout(editorNotifier);
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildWideLayout(EditorNotifier notifier) {
    return MultiSplitView(
      initialAreas: [
        Area(builder: (context, area) => _buildEditorColumn(notifier)),
        Area(builder: (context, area) => _buildPreviewColumn()),
      ],
    );
  }

  Widget _buildNarrowLayout(EditorNotifier notifier) {
    return _showPreview ? _buildPreviewColumn() : _buildEditorColumn(notifier);
  }

  Widget _buildMenuBar() {
    final actionsValue = ref.watch(actionsProvider(widget.contentItemId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          const Spacer(),
          actionsValue.when(
            data: (actions) => Row(
              children: actions.map((action) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ElevatedButton(
                    onPressed: () => _executeAction(action.command),
                    child: Text(action.label),
                  ),
                );
              }).toList(),
            ),
            error: (err, stack) => const Icon(Icons.error_outline, color: Colors.red),
            loading: () => const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: _showPreview ? 'Show Editor' : 'Show Preview',
            icon: Icon(_showPreview ? Icons.edit : Icons.visibility),
            onPressed: () {
              setState(() {
                _showPreview = !_showPreview;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEditorColumn(EditorNotifier notifier) {
    final editorState = ref.watch(editorProvider(widget.contentItemId));
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _titleController,
                  onChanged: (value) => notifier.onTextChanged(title: value),
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    border: InputBorder.none,
                  ),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _contentController,
                    onChanged: (value) => notifier.onTextChanged(content: value),
                    decoration: const InputDecoration(
                      hintText: 'Start writing...',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    expands: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildSavedIndicator(editorState.saveStatus),
      ],
    );
  }

  Widget _buildPreviewColumn() {
    final editorState = ref.watch(editorProvider(widget.contentItemId));
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            editorState.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Markdown(
              data: editorState.content,
              selectable: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedIndicator(SaveStatus saveStatus) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnimatedOpacity(
          opacity: saveStatus != SaveStatus.unsaved ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Text(
            saveStatus == SaveStatus.saving ? 'Saving...' : 'Saved',
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ),
      ),
    );
  }
}
