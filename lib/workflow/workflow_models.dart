import 'package:flutter/material.dart';

// A map to convert icon names from the DB to actual Flutter Icons.
const Map<String, IconData> iconMap = {
  'folder_special_outlined': Icons.folder_special_outlined,
  'lightbulb_outline': Icons.lightbulb_outline,
  'article_outlined': Icons.article_outlined,
  'movie_outlined': Icons.movie_outlined,
  'campaign_outlined': Icons.campaign_outlined,
  'default': Icons.help_outline,
};

// Enum to manage the different states of our save indicator.
enum SaveStatus { unsaved, saving, saved }

// Represents a single action in the workflow.
class WorkflowAction {
  const WorkflowAction({required this.label, required this.command});
  final String label;
  final String command;
}

// Represents a single state in the workflow, which contains its available actions.
class WorkflowState {
  const WorkflowState({required this.name, required this.actions});
  final String name;
  final List<WorkflowAction> actions;
}

// Represents a single content type in the workflow, which contains its possible states.
class WorkflowType {
  const WorkflowType({
    required this.name,
    required this.icon,
    required this.displayOrder,
    required this.states,
  });
  final String name;
  final IconData icon;
  final int displayOrder;
  final List<WorkflowState> states;
}

// Represents the entire parsed workflow definition.
class Workflow {
  const Workflow({
    required this.types,
  });

  final List<WorkflowType> types;

  // Factory to parse the new nested JSON structure.
  factory Workflow.fromJson(Map<String, dynamic> json) {
    final workflowData = json['workflow'];

    final types = (workflowData['types'] as List).map((typeJson) {
      final iconName = typeJson['icon_name'] as String? ?? 'default';
      
      final states = (typeJson['states'] as List).map((stateJson) {
        final actions = (stateJson['actions'] as List).map((actionJson) {
          return WorkflowAction(
            label: actionJson['label'],
            command: actionJson['command'],
          );
        }).toList();
        
        return WorkflowState(
          name: stateJson['name'],
          actions: actions,
        );
      }).toList();

      return WorkflowType(
        name: typeJson['name'],
        icon: iconMap[iconName] ?? Icons.help_outline,
        displayOrder: typeJson['display_order'],
        states: states,
      );
    }).toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return Workflow(types: types);
  }

  // Helper method to easily find the available actions for a given type and state.
  List<WorkflowAction> getActionsFor(String typeName, String stateName) {
    try {
      final type = types.firstWhere((t) => t.name == typeName);
      final state = type.states.firstWhere((s) => s.name == stateName);
      return state.actions;
    } catch (e) {
      // If no matching type or state is found, return an empty list.
      return [];
    }
  }
}
