import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config.dart';
import '../main.dart';
import '../list/list_provider.dart';
import '../workflow/workflow_models.dart';
import '../workflow/workflow_provider.dart';

// The data model for our editor's state.
class EditorState {
  EditorState({
    this.title = '',
    this.content = '',
    this.sourceUrl,
    this.thumbnailUrl,
    this.saveStatus = SaveStatus.saved,
    this.isLoading = true,
    this.editorType = 'markdown',
    this.typeName = '',
    this.parentId,
  });

  final String title;
  final String content;
  final String? sourceUrl;
  final String? thumbnailUrl;
  final SaveStatus saveStatus;
  final bool isLoading;
  final String editorType;
  final String typeName;
  final String? parentId;

  EditorState copyWith({
    String? title,
    String? content,
    String? sourceUrl,
    String? thumbnailUrl,
    SaveStatus? saveStatus,
    bool? isLoading,
    String? editorType,
    String? typeName,
    String? parentId,
  }) {
    return EditorState(
      title: title ?? this.title,
      content: content ?? this.content,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      saveStatus: saveStatus ?? this.saveStatus,
      isLoading: isLoading ?? this.isLoading,
      editorType: editorType ?? this.editorType,
      typeName: typeName ?? this.typeName,
      parentId: parentId ?? this.parentId,
    );
  }
}

// The Notifier class that acts as our controller.
class EditorNotifier extends AutoDisposeFamilyNotifier<EditorState, String> {
  Timer? _debounce;

  @override
  EditorState build(String contentItemId) {
    _fetchInitialData();
    return EditorState();
  }

  Future<void> _fetchInitialData() async {
    try {
      final workflowData = await ref.read(workflowProvider.future);
      final workflow = workflowData.workflow;

      final itemResponse = await supabase
          .from('content_items')
          .select('type_name, parent_id')
          .eq('id', arg)
          .single();
      
      final typeName = itemResponse['type_name'] as String;
      final parentId = itemResponse['parent_id'] as String?;
      final typeInfo = workflow.types.firstWhere((t) => t.name == typeName);

      final versionResponse = await supabase.rpc(
        'get_latest_content_version',
        params: {'p_content_item_id': arg},
      );
      
      // ADDED: Log the raw response to see what the database is sending.
      debugLog('Raw version response: $versionResponse');

      if (versionResponse.isNotEmpty) {
        final data = versionResponse[0];
        state = state.copyWith(
          title: data['title'] ?? 'Untitled',
          content: data['content'] ?? '',
          sourceUrl: data['source_url'],
          thumbnailUrl: data['thumbnail_url'],
          isLoading: false,
          editorType: typeInfo.editorType,
          typeName: typeName,
          parentId: parentId,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          editorType: typeInfo.editorType,
          typeName: typeName,
          parentId: parentId,
        );
      }
    } catch (e) {
      debugLog('Error fetching initial text: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void onTextChanged({String? title, String? content}) {
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
        'p_author_signature': 'user'
      });
      
      // Invalidate the correct list provider so it refreshes.
      final params = ListProviderParams(typeName: state.typeName, parentId: state.parentId);
      ref.invalidate(listProvider(params));
      
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
