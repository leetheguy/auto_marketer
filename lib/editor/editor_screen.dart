import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_split_view/multi_split_view.dart';
import '../config.dart';
import '../main.dart';
import '../common/list_provider.dart';

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
      // Invalidate both providers so lists are fresh when we navigate back.
      ref.invalidate(listProvider(ContentType.article));
      ref.invalidate(listProvider(ContentType.idea));
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
          : Column(
              children: [
                _buildMenuBar(),
                const Divider(height: 1),
                Expanded(
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

  Widget _buildWideLayout() {
    return MultiSplitView(
      initialAreas: [
        Area(builder: (context, area) => _buildEditorColumn()),
        Area(builder: (context, area) => _buildPreviewColumn()),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return _showPreview ? _buildPreviewColumn() : _buildEditorColumn();
  }

  Widget _buildMenuBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          const Spacer(),
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

  Widget _buildEditorColumn() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Styled Title TextField
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    border: InputBorder.none,
                  ),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 16),
              // Styled Content TextField
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
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
              ),
            ],
          ),
        ),
        _buildSavedIndicator(),
      ],
    );
  }

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
