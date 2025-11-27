// Enums for Task Model
enum TaskSource {
  audit,
  standalone;

  String toJson() => name;

  static TaskSource fromJson(String json) {
    return TaskSource.values.firstWhere(
      (e) => e.name == json,
      orElse: () => TaskSource.standalone,
    );
  }
}

enum TaskType {
  oneTime,
  repetitive;

  String toJson() => name;

  static TaskType fromJson(String json) {
    return TaskType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => TaskType.oneTime,
    );
  }
}

enum TaskPriority {
  low,
  medium,
  high;

  String toJson() => name;

  static TaskPriority fromJson(String json) {
    return TaskPriority.values.firstWhere(
      (e) => e.name == json,
      orElse: () => TaskPriority.low,
    );
  }

  // Map from audit risk levels
  static TaskPriority fromRisk(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
        return TaskPriority.high;
      case 'medium':
        return TaskPriority.medium;
      case 'low':
      default:
        return TaskPriority.low;
    }
  }
}

enum TaskStatus {
  assigned,
  inProgress,
  pendingReview,
  completed,
  incomplete;

  String toJson() => name;

  static TaskStatus fromJson(String json) {
    return TaskStatus.values.firstWhere(
      (e) => e.name == json,
      orElse: () => TaskStatus.assigned,
    );
  }
}

class TaskModel {
  final String id;
  final String title;
  final String description;

  // Source & Context
  final TaskSource source;
  final String? auditReportId;
  final String? auditEntryId;
  final String? auditAreaId;
  final List<String> auditIssueIds;

  // Assignment
  final String createdBy; // Auditor email/id
  final List<String> assignedTo; // Can be multiple people (emails)
  final String clientId;
  final String projectId;

  // Timing
  final DateTime createdAt;
  final DateTime assignedDate;
  final DateTime dueDate;

  // Task Properties
  final TaskType type;
  final String? repeatFrequency; // 'daily', 'weekly', 'monthly'
  final TaskPriority priority;

  // Status & Progress
  final TaskStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? reviewedAt;

  // Staff Response
  final String staffComments;
  final List<String> staffImages; // Firebase Storage URLs
  final bool? complianceStatus; // Yes/No response

  // Admin Review
  final String adminComments;
  final bool? isApproved;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.source,
    this.auditReportId,
    this.auditEntryId,
    this.auditAreaId,
    List<String>? auditIssueIds,
    required this.createdBy,
    required this.assignedTo,
    required this.clientId,
    required this.projectId,
    required this.createdAt,
    required this.assignedDate,
    required this.dueDate,
    required this.type,
    this.repeatFrequency,
    required this.priority,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.reviewedAt,
    String? staffComments,
    List<String>? staffImages,
    this.complianceStatus,
    String? adminComments,
    this.isApproved,
  })  : auditIssueIds = auditIssueIds ?? [],
        staffComments = staffComments ?? '',
        staffImages = staffImages ?? [],
        adminComments = adminComments ?? '';

  // Validation helpers
  bool get isValid => title.trim().isNotEmpty && assignedTo.isNotEmpty;

  bool get isFromAudit => source == TaskSource.audit;
  bool get isStandalone => source == TaskSource.standalone;

  bool get isRepetitive => type == TaskType.repetitive;
  bool get isOneTime => type == TaskType.oneTime;

  bool get isAssigned => status == TaskStatus.assigned;
  bool get isInProgress => status == TaskStatus.inProgress;
  bool get isPendingReview => status == TaskStatus.pendingReview;
  bool get isCompleted => status == TaskStatus.completed;
  bool get isIncomplete => status == TaskStatus.incomplete;

  bool get isOverdue =>
      DateTime.now().isAfter(dueDate) &&
      !isCompleted &&
      !isIncomplete;

  bool get canBeEditedByStaff => isAssigned || isInProgress;
  bool get canBeReviewedByAdmin => isPendingReview;
  bool get isReadOnly => isCompleted || isIncomplete;

  bool get hasStaffResponse =>
      complianceStatus != null ||
      staffComments.trim().isNotEmpty ||
      staffImages.isNotEmpty;

  // Serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'source': source.toJson(),
      'auditReportId': auditReportId,
      'auditEntryId': auditEntryId,
      'auditAreaId': auditAreaId,
      'auditIssueIds': auditIssueIds,
      'createdBy': createdBy,
      'assignedTo': assignedTo,
      'clientId': clientId,
      'projectId': projectId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'assignedDate': assignedDate.millisecondsSinceEpoch,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'type': type.toJson(),
      'repeatFrequency': repeatFrequency,
      'priority': priority.toJson(),
      'status': status.toJson(),
      'startedAt': startedAt?.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'reviewedAt': reviewedAt?.millisecondsSinceEpoch,
      'staffComments': staffComments,
      'staffImages': staffImages,
      'complianceStatus': complianceStatus,
      'adminComments': adminComments,
      'isApproved': isApproved,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      source: TaskSource.fromJson(map['source'] ?? 'standalone'),
      auditReportId: map['auditReportId'],
      auditEntryId: map['auditEntryId'],
      auditAreaId: map['auditAreaId'],
      auditIssueIds: map['auditIssueIds'] != null
          ? List<String>.from(map['auditIssueIds'])
          : [],
      createdBy: map['createdBy'] ?? '',
      assignedTo: map['assignedTo'] != null
          ? List<String>.from(map['assignedTo'])
          : [],
      clientId: map['clientId'] ?? '',
      projectId: map['projectId'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      assignedDate: map['assignedDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['assignedDate'])
          : DateTime.now(),
      dueDate: map['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'])
          : DateTime.now(),
      type: TaskType.fromJson(map['type'] ?? 'oneTime'),
      repeatFrequency: map['repeatFrequency'],
      priority: TaskPriority.fromJson(map['priority'] ?? 'low'),
      status: TaskStatus.fromJson(map['status'] ?? 'assigned'),
      startedAt: map['startedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startedAt'])
          : null,
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null,
      reviewedAt: map['reviewedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['reviewedAt'])
          : null,
      staffComments: map['staffComments'] ?? '',
      staffImages: map['staffImages'] != null
          ? List<String>.from(map['staffImages'])
          : [],
      complianceStatus: map['complianceStatus'],
      adminComments: map['adminComments'] ?? '',
      isApproved: map['isApproved'],
    );
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    TaskSource? source,
    String? auditReportId,
    String? auditEntryId,
    String? auditAreaId,
    List<String>? auditIssueIds,
    String? createdBy,
    List<String>? assignedTo,
    String? clientId,
    String? projectId,
    DateTime? createdAt,
    DateTime? assignedDate,
    DateTime? dueDate,
    TaskType? type,
    String? repeatFrequency,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? reviewedAt,
    String? staffComments,
    List<String>? staffImages,
    bool? complianceStatus,
    String? adminComments,
    bool? isApproved,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      source: source ?? this.source,
      auditReportId: auditReportId ?? this.auditReportId,
      auditEntryId: auditEntryId ?? this.auditEntryId,
      auditAreaId: auditAreaId ?? this.auditAreaId,
      auditIssueIds: auditIssueIds ?? this.auditIssueIds,
      createdBy: createdBy ?? this.createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      clientId: clientId ?? this.clientId,
      projectId: projectId ?? this.projectId,
      createdAt: createdAt ?? this.createdAt,
      assignedDate: assignedDate ?? this.assignedDate,
      dueDate: dueDate ?? this.dueDate,
      type: type ?? this.type,
      repeatFrequency: repeatFrequency ?? this.repeatFrequency,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      staffComments: staffComments ?? this.staffComments,
      staffImages: staffImages ?? this.staffImages,
      complianceStatus: complianceStatus ?? this.complianceStatus,
      adminComments: adminComments ?? this.adminComments,
      isApproved: isApproved ?? this.isApproved,
    );
  }

  @override
  String toString() {
    return 'TaskModel(id: $id, title: $title, status: $status, source: $source, priority: $priority)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TaskModel &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.source == source &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        source.hashCode ^
        status.hashCode;
  }

}
