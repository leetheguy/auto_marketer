import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import '../config.dart';
import '../main.dart';
import '../text/text_provider.dart';

// Enum to manage the different states of our save indicator.
enum SaveStatus { unsaved, saving, saved }

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
  bool _isLoading = true;
  Timer? _debounce;
  SaveStatus _saveStatus = SaveStatus.saved;
  bool _showPreview = false; // For mobile view toggle

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _fetchInitialData();

    // Add listeners to trigger the debouncer and update the preview in real-time
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTextChanged);
    _contentController.removeListener(_onTextChanged);
    _debounce?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    try {
      final response = await supabase.rpc(
        'get_latest_text_version',
        params: {'p_content_item_id': widget.contentItemId},
      );
      
      if (response.isNotEmpty) {
        final data = response[0];
        _titleController.text = data['title'] ?? 'Untitled';
        _contentController.text = data['content'] ?? '';
      }
    } catch (e) {
      debugLog('Error fetching initial text: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onTextChanged() {
    // This setState call ensures the markdown preview updates as you type.
    setState(() {}); 

    if (_saveStatus != SaveStatus.saving) {
      setState(() {
        _saveStatus = SaveStatus.unsaved;
      });
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: AppConfig.editorDebounceMilliseconds), () {
      _saveChanges();
    });
  }

  Future<void> _saveChanges() async {
    setState(() {
      _saveStatus = SaveStatus.saving;
    });

    try {
      await supabase.rpc('upsert_text_version', params: {
        'p_content_item_id': widget.contentItemId,
        'p_title': _titleController.text,
        'p_content': _contentController.text,
      });
      ref.invalidate(articlesProvider);
      debugLog('Changes saved.');
      
      if (mounted) {
        setState(() {
          _saveStatus = SaveStatus.saved;
        });
      }
    } catch (e) {
      debugLog('Error saving changes: $e');
      if (mounted) {
        setState(() {
          _saveStatus = SaveStatus.unsaved;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column( // Main layout is now a Column
              children: [
                _buildMenuBar(), // Menu bar is always at the top
                const Divider(height: 1),
                Expanded( // The rest of the screen fills the available space
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 700) {
                        return _buildWideLayout();
                      } else {
                        return _buildNarrowLayout();
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // Widget for the side-by-side desktop/tablet layout with a slider
  Widget _buildWideLayout() {
    // Using the correct syntax with initialAreas and Area.
    return MultiSplitView(
      initialAreas: [
        Area(builder: (context, area) => _buildEditorColumn()),
        Area(builder: (context, area) => _buildPreviewColumn()),
      ],
    );
  }

  // Widget for the toggled mobile layout
  Widget _buildNarrowLayout() {
    // Just show one or the other based on the toggle
    return _showPreview ? _buildPreviewColumn() : _buildEditorColumn();
  }

  // The menu bar for all layouts
  Widget _buildMenuBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          // This is where the magic wand and other buttons will go.
          // For now, we just have the preview toggle.
          const Spacer(), // Pushes the button to the right
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

  // The reusable editor part of the UI
  Widget _buildEditorColumn() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Title',
                  border: InputBorder.none,
                ),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    hintText: 'Start writing...',
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  expands: true,
                ),
              ),
            ],
          ),
        ),
        _buildSavedIndicator(),
      ],
    );
  }

  // The reusable preview part of the UI
  Widget _buildPreviewColumn() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _titleController.text,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Markdown(
              data: _contentController.text,
              selectable: true,
            ),
          ),
        ],
      ),
    );
  }

  // The saved indicator widget
  Widget _buildSavedIndicator() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnimatedOpacity(
          opacity: _saveStatus != SaveStatus.unsaved ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Text(
            _saveStatus == SaveStatus.saving ? 'Saving...' : 'Saved',
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ),
      ),
    );
  }
}
