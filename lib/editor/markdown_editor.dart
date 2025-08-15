import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:multi_split_view/multi_split_view.dart';
import '../workflow/workflow_models.dart';

// This is a "dumb" widget. It has no state or logic of its own.
// It receives everything it needs to function from its parent.
class MarkdownEditor extends StatelessWidget {
  const MarkdownEditor({
    super.key,
    required this.titleController,
    required this.contentController,
    required this.onTitleChanged,
    required this.onContentChanged,
    required this.saveStatus,
  });

  final TextEditingController titleController;
  final TextEditingController contentController;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onContentChanged;
  final SaveStatus saveStatus;

  @override
  Widget build(BuildContext context) {
    // This widget is now just for layout.
    // A more advanced version would have the preview toggle here.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 700) {
          return _buildWideLayout(context);
        } else {
          return _buildEditorColumn(context);
        }
      },
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return MultiSplitView(
      initialAreas: [
        Area(builder: (context, area) => _buildEditorColumn(context)),
        Area(builder: (context, area) => _buildPreviewColumn(context)),
      ],
    );
  }

  Widget _buildEditorColumn(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withAlpha(128), width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: titleController,
                  onChanged: onTitleChanged,
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
                    border: Border.all(color: Colors.white.withAlpha(128), width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: contentController,
                    onChanged: onContentChanged,
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
        _buildSavedIndicator(),
      ],
    );
  }

  Widget _buildPreviewColumn(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titleController.text,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Markdown(
              data: contentController.text,
              selectable: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedIndicator() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnimatedOpacity(
          opacity: saveStatus != SaveStatus.unsaved ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Text(
            saveStatus == SaveStatus.saving ? 'Saving...' : 'Saved',
            style: TextStyle(color: Colors.white.withAlpha(128)),
          ),
        ),
      ),
    );
  }
}
