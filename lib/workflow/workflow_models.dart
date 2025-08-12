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

// Enum to manage the different states of our save indicator. (MOVED HERE)
enum SaveStatus { unsaved, saving, saved }

// Represents a single action in the workflow.
class WorkflowAction {
  const WorkflowAction({required this.label, required this.command});
  final String label;
  final String command;
}

// Represents a single state in the workflow.
class WorkflowState {
  const WorkflowState({required this.name});
  final String name;
}

// Represents a single content type in the workflow.
class WorkflowType {
  const WorkflowType({
    required this.name,
    required this.icon,
    required this.displayOrder,
  });
  final String name;
  final IconData icon;
  final int displayOrder;
}

// Represents the entire parsed workflow definition.
class Workflow {
  const Workflow({
    required this.types,
    required this.states,
    required this.actions,
    required this.rules,
  });

  final List<WorkflowType> types;
  final List<WorkflowState> states;
  final List<WorkflowAction> actions;
  final Map<String, Map<String, List<WorkflowAction>>> rules; // type -> state -> actions

  // Factory to parse the raw JSON from Supabase into our structured model.
  factory Workflow.fromJson(Map<String, dynamic> json) {
    final workflowData = json['workflow'];

    final types = (workflowData['types'] as List).map((typeJson) {
      final iconName = typeJson['icon_name'] as String? ?? 'default';
      return WorkflowType(
        name: typeJson['name'],
        icon: iconMap[iconName] ?? Icons.help_outline,
        displayOrder: typeJson['display_order'],
      );
    }).toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    final states = (workflowData['states'] as List)
        .map((stateJson) => WorkflowState(name: stateJson['name']))
        .toList();

    final actions = (workflowData['actions'] as List)
        .map((actionJson) => WorkflowAction(
              label: actionJson['label'],
              command: actionJson['command'],
            ))
        .toList();

    // Parse the rules into a nested map for easy lookup: rules[typeName][stateName]
    final rules = <String, Map<String, List<WorkflowAction>>>{};
    for (var ruleJson in (workflowData['rules'] as List)) {
      final typeName = ruleJson['type'];
      final stateName = ruleJson['state'];
      final actionLabel = ruleJson['action'];

      final action = actions.firstWhere((a) => a.label == actionLabel);

      rules.putIfAbsent(typeName, () => {});
      rules[typeName]!.putIfAbsent(stateName, () => []);
      rules[typeName]![stateName]!.add(action);
    }

    return Workflow(
      types: types,
      states: states,
      actions: actions,
      rules: rules,
    );
  }
}
