import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';

class ActionService {
  Future<String?> createNewIdea({
    required int accountId,
    required int workflowId,
  }) async {
    try {
      final url = Uri.parse(AppConfig.getWebhookUrl('create-idea'));
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'account_id': accountId,
          'workflow_id': workflowId,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['content_item_id']?.toString();
      } else {
        consoleInfo(
            'Failed to create new idea. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      consoleInfo('Error creating new idea: $e');
      return null;
    }
  }

  Future<void> executeAction({
    required String command,
    required String contentItemId,
  }) async {
    consoleInfo("here we go $command $contentItemId");
    try {
      final url = Uri.parse(AppConfig.getWebhookUrl(command));
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'content_item_id': contentItemId,
        }),
      );

      if (response.statusCode == 200) {
        consoleInfo('Action "$command" executed successfully for $contentItemId');
      } else {
        consoleInfo(
            'Failed to execute action "$command". Status code: ${response.statusCode} for $contentItemId');
      }
    } catch (e) {
      consoleInfo('Error executing action "$command" for $contentItemId: $e');
    }
  }
}

final actionServiceProvider = Provider<ActionService>((ref) {
  return ActionService();
});
