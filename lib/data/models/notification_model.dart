enum NotificationType {
  taskAssigned,
  taskUpdated,
  taskCompleted,
  taskRejected,
  taskApproved,
  taskOverdue,
  reportCreated;

  String toJson() => name;

  static NotificationType fromJson(String json) {
    return NotificationType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => NotificationType.taskAssigned,
    );
  }
}

class NotificationModel {
  final String id;
  final String userId; // Who should receive this notification
  final String? taskId; // Related task (optional)
  final String? reportId; // Related report (optional)
  final NotificationType type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata; // Additional data

  NotificationModel({
    required this.id,
    required this.userId,
    this.taskId,
    this.reportId,
    required this.type,
    required this.title,
    required this.message,
    this.isRead = false,
    required this.createdAt,
    this.metadata,
  });

  // Helper getters
  bool get isUnread => !isRead;
  bool get isTaskRelated => taskId != null;
  bool get isReportRelated => reportId != null;

  // Age of notification
  Duration get age => DateTime.now().difference(createdAt);
  bool get isRecent => age.inHours < 24;
  bool get isToday => createdAt.day == DateTime.now().day &&
      createdAt.month == DateTime.now().month &&
      createdAt.year == DateTime.now().year;

  // Serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'taskId': taskId,
      'reportId': reportId,
      'type': type.toJson(),
      'title': title,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      taskId: map['taskId'],
      reportId: map['reportId'],
      type: NotificationType.fromJson(map['type'] ?? 'taskAssigned'),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? taskId,
    String? reportId,
    NotificationType? type,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      taskId: taskId ?? this.taskId,
      reportId: reportId ?? this.reportId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, userId: $userId, type: $type, title: $title, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationModel &&
        other.id == id &&
        other.userId == userId &&
        other.type == type &&
        other.isRead == isRead;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        type.hashCode ^
        isRead.hashCode;
  }

  // Factory methods for common notification types
  factory NotificationModel.taskAssigned({
    required String id,
    required String userId,
    required String taskId,
    required String taskTitle,
    required String assignedBy,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      taskId: taskId,
      type: NotificationType.taskAssigned,
      title: 'New Task Assigned',
      message: '$assignedBy assigned you a task: "$taskTitle"',
      createdAt: DateTime.now(),
      metadata: {
        'taskId': taskId,
        'taskTitle': taskTitle,
        'assignedBy': assignedBy,
      },
    );
  }

  factory NotificationModel.taskCompleted({
    required String id,
    required String userId,
    required String taskId,
    required String taskTitle,
    required String completedBy,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      taskId: taskId,
      type: NotificationType.taskCompleted,
      title: 'Task Completed',
      message: '$completedBy completed the task: "$taskTitle"',
      createdAt: DateTime.now(),
      metadata: {
        'taskId': taskId,
        'taskTitle': taskTitle,
        'completedBy': completedBy,
      },
    );
  }

  factory NotificationModel.taskApproved({
    required String id,
    required String userId,
    required String taskId,
    required String taskTitle,
    required String approvedBy,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      taskId: taskId,
      type: NotificationType.taskApproved,
      title: 'Task Approved',
      message: '$approvedBy approved your task: "$taskTitle"',
      createdAt: DateTime.now(),
      metadata: {
        'taskId': taskId,
        'taskTitle': taskTitle,
        'approvedBy': approvedBy,
      },
    );
  }

  factory NotificationModel.taskRejected({
    required String id,
    required String userId,
    required String taskId,
    required String taskTitle,
    required String rejectedBy,
    String? reason,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      taskId: taskId,
      type: NotificationType.taskRejected,
      title: 'Task Needs Revision',
      message: reason != null
          ? '$rejectedBy requested changes: $reason'
          : '$rejectedBy requested changes to "$taskTitle"',
      createdAt: DateTime.now(),
      metadata: {
        'taskId': taskId,
        'taskTitle': taskTitle,
        'rejectedBy': rejectedBy,
        'reason': reason,
      },
    );
  }

  factory NotificationModel.reportCreated({
    required String id,
    required String userId,
    required String reportId,
    required String clientName,
    required String createdBy,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      reportId: reportId,
      type: NotificationType.reportCreated,
      title: 'New Audit Report',
      message: '$createdBy created a new audit report for $clientName',
      createdAt: DateTime.now(),
      metadata: {
        'reportId': reportId,
        'clientName': clientName,
        'createdBy': createdBy,
      },
    );
  }
}
