import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:surakshith/data/models/task_model.dart';

/// Template for creating repetitive tasks
/// Used to define patterns that generate daily/weekly task instances
class TaskTemplateModel {
  final String id;
  final String title;
  final String description;
  final String clientId;
  final String projectId;
  final List<String> defaultAssignees; // Default users to assign
  final TaskPriority priority;
  final RepeatFrequency frequency;
  final TimeOfDay? reminderTime; // Preferred time for daily tasks
  final bool isActive; // Can be disabled without deletion
  final String createdBy;
  final DateTime createdAt;
  final DateTime? lastGeneratedAt; // Track last time task was generated
  final Map<String, dynamic>? metadata; // Additional custom fields

  TaskTemplateModel({
    required this.id,
    required this.title,
    required this.description,
    required this.clientId,
    required this.projectId,
    this.defaultAssignees = const [],
    required this.priority,
    required this.frequency,
    this.reminderTime,
    this.isActive = true,
    required this.createdBy,
    required this.createdAt,
    this.lastGeneratedAt,
    this.metadata,
  });

  // Factory constructor from Firestore document
  factory TaskTemplateModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskTemplateModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      clientId: data['clientId'] ?? '',
      projectId: data['projectId'] ?? '',
      defaultAssignees: List<String>.from(data['defaultAssignees'] ?? []),
      priority: TaskPriority.values.firstWhere(
        (e) => e.toString() == 'TaskPriority.${data['priority']}',
        orElse: () => TaskPriority.medium,
      ),
      frequency: RepeatFrequency.values.firstWhere(
        (e) => e.toString() == 'RepeatFrequency.${data['frequency']}',
        orElse: () => RepeatFrequency.daily,
      ),
      reminderTime: data['reminderTime'] != null
          ? TimeOfDay(
              hour: data['reminderTime']['hour'] ?? 9,
              minute: data['reminderTime']['minute'] ?? 0,
            )
          : null,
      isActive: data['isActive'] ?? true,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastGeneratedAt: (data['lastGeneratedAt'] as Timestamp?)?.toDate(),
      metadata: data['metadata'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'clientId': clientId,
      'projectId': projectId,
      'defaultAssignees': defaultAssignees,
      'priority': priority.name,
      'frequency': frequency.name,
      'reminderTime': reminderTime != null
          ? {
              'hour': reminderTime!.hour,
              'minute': reminderTime!.minute,
            }
          : null,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastGeneratedAt':
          lastGeneratedAt != null ? Timestamp.fromDate(lastGeneratedAt!) : null,
      'metadata': metadata,
    };
  }

  // Copy with method for updates
  TaskTemplateModel copyWith({
    String? id,
    String? title,
    String? description,
    String? clientId,
    String? projectId,
    List<String>? defaultAssignees,
    TaskPriority? priority,
    RepeatFrequency? frequency,
    TimeOfDay? reminderTime,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? lastGeneratedAt,
    Map<String, dynamic>? metadata,
  }) {
    return TaskTemplateModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      clientId: clientId ?? this.clientId,
      projectId: projectId ?? this.projectId,
      defaultAssignees: defaultAssignees ?? this.defaultAssignees,
      priority: priority ?? this.priority,
      frequency: frequency ?? this.frequency,
      reminderTime: reminderTime ?? this.reminderTime,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      lastGeneratedAt: lastGeneratedAt ?? this.lastGeneratedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper to get frequency display text
  String get frequencyText {
    switch (frequency) {
      case RepeatFrequency.daily:
        return 'Daily';
      case RepeatFrequency.weekly:
        return 'Weekly';
      case RepeatFrequency.monthly:
        return 'Monthly';
    }
  }

  // Check if template should generate task today
  bool shouldGenerateToday() {
    if (!isActive) return false;
    if (lastGeneratedAt == null) return true;

    final now = DateTime.now();
    final lastGen = lastGeneratedAt!;

    switch (frequency) {
      case RepeatFrequency.daily:
        // Generate if last generated was before today
        return lastGen.year != now.year ||
            lastGen.month != now.month ||
            lastGen.day != now.day;

      case RepeatFrequency.weekly:
        // Generate if last generated was more than 7 days ago
        final daysSinceLastGen = now.difference(lastGen).inDays;
        return daysSinceLastGen >= 7;

      case RepeatFrequency.monthly:
        // Generate if last generated was in a different month
        return lastGen.year != now.year || lastGen.month != now.month;
    }
  }

  // Generate a task from this template
  TaskModel generateTask({
    String? taskId,
    DateTime? dueDate,
    List<String>? assignees,
  }) {
    final now = DateTime.now();

    // Calculate due date based on frequency if not provided
    DateTime calculatedDueDate = dueDate ?? _calculateDueDate(now);

    return TaskModel(
      id: taskId ?? '',
      title: title,
      description: description,
      source: TaskSource.standalone,
      auditReportId: null,
      auditEntryId: null,
      auditAreaId: null,
      auditIssueIds: const [],
      createdBy: createdBy,
      assignedTo: assignees ?? defaultAssignees,
      clientId: clientId,
      projectId: projectId,
      createdAt: now,
      assignedDate: now,
      dueDate: calculatedDueDate,
      type: TaskType.repetitive,
      repeatFrequency: frequency.name,
      priority: priority,
      status: TaskStatus.assigned,
      complianceStatus: null,
      startedAt: null,
      completedAt: null,
      staffComments: null,
      adminComments: null,
      staffImages: const [],
    );
  }

  // Calculate due date based on frequency
  DateTime _calculateDueDate(DateTime fromDate) {
    final time = reminderTime ?? const TimeOfDay(hour: 17, minute: 0); // Default 5 PM

    switch (frequency) {
      case RepeatFrequency.daily:
        // Due by end of same day
        return DateTime(
          fromDate.year,
          fromDate.month,
          fromDate.day,
          time.hour,
          time.minute,
        );

      case RepeatFrequency.weekly:
        // Due in 7 days
        final dueDay = fromDate.add(const Duration(days: 7));
        return DateTime(
          dueDay.year,
          dueDay.month,
          dueDay.day,
          time.hour,
          time.minute,
        );

      case RepeatFrequency.monthly:
        // Due end of month
        final nextMonth = DateTime(fromDate.year, fromDate.month + 1, 1);
        final lastDayOfMonth = nextMonth.subtract(const Duration(days: 1));
        return DateTime(
          lastDayOfMonth.year,
          lastDayOfMonth.month,
          lastDayOfMonth.day,
          time.hour,
          time.minute,
        );
    }
  }
}

/// Repeat frequency enum
enum RepeatFrequency {
  daily,
  weekly,
  monthly,
}
