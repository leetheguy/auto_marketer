import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../editor/editor_screen.dart'; // This import fixes the error.
import 'list_provider.dart';

class ListScreen extends ConsumerWidget {
  const ListScreen({
    super.key,
    this.typeName,
    this.parentId,
  }) : assert(typeName != null || parentId != null, 'Must provide either a typeName or a parentId');

  final String? typeName;
  final String? parentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ListProviderParams(typeName: typeName, parentId: parentId);
    final listAsyncValue = ref.watch(listProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: Text(typeName ?? 'Project Contents'),
      ),
      body: listAsyncValue.when(
        data: (items) => ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(item.icon),
                title: Text(item.title),
                subtitle: Text(item.subtitle),
                onTap: () {
                  // This is the core of our hierarchical navigation.
                  if (item.typeName == 'Project') {
                    // If the item is a Project, navigate to another ListScreen showing its children.
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ListScreen(parentId: item.id),
                      ),
                    );
                  } else {
                    // Otherwise, it's a regular content item, so navigate to the editor.
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EditorScreen(contentItemId: item.id),
                      ),
                    );
                  }
                },
              ),
            );
          },
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
