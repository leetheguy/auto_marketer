import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      
      debugLog('Response from get_latest_text_version: $response');

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
          : Stack(
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
                Align(
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
                ),
              ],
            ),
    );
  }
}