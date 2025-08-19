import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart'; // We'll need this for uploads
import '../config.dart';
import 'editor_provider.dart';
import 'image_editor.dart';
import 'markdown_editor.dart';

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
  
  // Future<void> _executeAction(String command) async {
  //   // ... (This method is unchanged)
  // }

  // New method to handle the image upload process.
  Future<void> _handleImageUpload() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    // This is where you would call the 'upload-image' n8n webhook,
    // sending the image data as a multipart/form-data request.
    debugLog('Image picked: ${image.path}');
    // For now, we'll just log it. The actual upload requires a more complex HTTP request.
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorProvider(widget.contentItemId));
    final editorNotifier = ref.read(editorProvider(widget.contentItemId).notifier);
    
    ref.listen(editorProvider(widget.contentItemId), (previous, next) {
      if (previous?.isLoading == true && !next.isLoading) {
        if (_titleController.text != next.title) {
          _titleController.text = next.title;
        }
        if (_contentController.text != next.content) {
          _contentController.text = next.content;
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(editorState.isLoading ? 'Loading...' : editorState.title),
        actions: [
          _buildGlobalMenuBar(),
        ],
      ),
      body: editorState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildEditorBody(editorState, editorNotifier),
    );
  }

  Widget _buildGlobalMenuBar() {
    // ... (This method is unchanged)
    return Container(); // Placeholder
  }

  Widget _buildEditorBody(EditorState editorState, EditorNotifier editorNotifier) {
    switch (editorState.editorType) {
      case 'image':
        // The screen now passes the sourceUrl and the upload callback to the dumb widget.
        return ImageEditor(
          sourceUrl: editorState.sourceUrl,
          onUpload: _handleImageUpload,
        );
      case 'markdown':
      default:
        // It also passes the controllers and callbacks to the dumb MarkdownEditor.
        return MarkdownEditor(
          titleController: _titleController,
          contentController: _contentController,
          onTitleChanged: (value) => editorNotifier.onTextChanged(title: value),
          onContentChanged: (value) => editorNotifier.onTextChanged(content: value),
          saveStatus: editorState.saveStatus,
        );
    }
  }
}
