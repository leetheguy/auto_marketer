import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config.dart';
import '../main.dart';
import '../common/list_provider.dart'; // This import fixes the error.

// Enum to manage the different states of our save indicator.
enum SaveStatus { unsaved, saving, saved }

// The data model for our editor's state.
class EditorState {
  EditorState({
    this.title = '',
    this.content = '',
    this.saveStatus = SaveStatus.saved,
    this.isLoading = true,
  });

  final String title;
  final String content;
  final SaveStatus saveStatus;
  final bool isLoading;

  EditorState copyWith({
    String? title,
    String? content,
    SaveStatus? saveStatus,
    bool? isLoading,
  }) {
    return EditorState(
      title: title ?? this.title,
      content: content ?? this.content,
      saveStatus: saveStatus ?? this.saveStatus,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// The Notifier class that acts as our controller.
class EditorNotifier extends AutoDisposeFamilyNotifier<EditorState, String> {
  Timer? _debounce;

  // The build method is called when the provider is first read.
  @override
  EditorState build(String contentItemId) {
    // Fetch the initial data when the provider is initialized.
    _fetchInitialData();
    // Return the initial loading state.
    return EditorState();
  }

  Future<void> _fetchInitialData() async {
    try {
      final response = await supabase.rpc(
        'get_latest_content_version',
        params: {'p_content_item_id': arg}, // 'arg' is the contentItemId from the family
      );
      
      if (response.isNotEmpty) {
        final data = response[0];
        state = state.copyWith(
          title: data['title'] ?? 'Untitled',
          content: data['content'] ?? '',
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      debugLog('Error fetching initial text: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  // Public method to be called from the UI when text changes.
  void onTextChanged({String? title, String? content}) {
    // Update the state immediately to reflect the new text.
    state = state.copyWith(
      title: title,
      content: content,
      saveStatus: SaveStatus.unsaved,
    );

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: AppConfig.editorDebounceMilliseconds), () {
      _saveChanges();
    });
  }

  Future<void> _saveChanges() async {
    state = state.copyWith(saveStatus: SaveStatus.saving);

    try {
      await supabase.rpc('upsert_content_version', params: {
        'p_content_item_id': arg,
        'p_title': state.title,
        'p_content': state.content,
        'p_author_signature': 'user' // Placeholder signature
      });
      
      // Invalidate list providers to refresh them.
      ref.invalidate(listProvider(const ListProviderParams(typeName: 'Article')));
      ref.invalidate(listProvider(const ListProviderParams(typeName: 'Idea')));
      
      debugLog('Changes saved.');
      state = state.copyWith(saveStatus: SaveStatus.saved);
    } catch (e) {
      debugLog('Error saving changes: $e');
      state = state.copyWith(saveStatus: SaveStatus.unsaved);
    }
  }
}

// The final provider that we'll use in our UI.
final editorProvider =
    NotifierProvider.autoDispose.family<EditorNotifier, EditorState, String>(
  () => EditorNotifier(),
);
