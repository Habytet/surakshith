class AuditAreaEntryModel {
  final String id;
  final String reportId;
  final String auditAreaId; // References audit area from management
  final String responsiblePersonId; // References responsible person from management
  final List<String> auditIssueIds; // References audit issues from management (multi-select)
  final String risk; // 'low', 'medium', 'high'
  final String observation;
  final String recommendation;
  final DateTime? deadlineDate; // Optional deadline
  final List<String> imageUrls; // Firebase Storage URLs (max 2)
  final DateTime? createdAt;

  AuditAreaEntryModel({
    required this.id,
    required this.reportId,
    required this.auditAreaId,
    required this.responsiblePersonId,
    List<String>? auditIssueIds,
    required this.risk,
    required this.observation,
    required this.recommendation,
    this.deadlineDate,
    List<String>? imageUrls,
    this.createdAt,
  })  : imageUrls = imageUrls ?? [],
        auditIssueIds = auditIssueIds ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reportId': reportId,
      'auditAreaId': auditAreaId,
      'responsiblePersonId': responsiblePersonId,
      'auditIssueIds': auditIssueIds,
      'risk': risk,
      'observation': observation,
      'recommendation': recommendation,
      'deadlineDate': deadlineDate?.millisecondsSinceEpoch,
      'imageUrls': imageUrls,
      'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }

  factory AuditAreaEntryModel.fromMap(Map<String, dynamic> map) {
    // Handle backward compatibility: convert old auditIssueId to auditIssueIds list
    List<String> auditIssueIds = [];
    if (map['auditIssueIds'] != null) {
      auditIssueIds = List<String>.from(map['auditIssueIds']);
    } else if (map['auditIssueId'] != null && map['auditIssueId'].toString().isNotEmpty) {
      // Old format: single auditIssueId -> convert to list
      auditIssueIds = [map['auditIssueId'].toString()];
    }

    return AuditAreaEntryModel(
      id: map['id'] ?? '',
      reportId: map['reportId'] ?? '',
      auditAreaId: map['auditAreaId'] ?? '',
      responsiblePersonId: map['responsiblePersonId'] ?? '',
      auditIssueIds: auditIssueIds,
      risk: map['risk'] ?? 'low',
      observation: map['observation'] ?? '',
      recommendation: map['recommendation'] ?? '',
      deadlineDate: map['deadlineDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['deadlineDate'])
          : null,
      imageUrls: map['imageUrls'] != null
          ? List<String>.from(map['imageUrls'])
          : [],
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
    );
  }

  AuditAreaEntryModel copyWith({
    String? id,
    String? reportId,
    String? auditAreaId,
    String? responsiblePersonId,
    List<String>? auditIssueIds,
    String? risk,
    String? observation,
    String? recommendation,
    DateTime? deadlineDate,
    List<String>? imageUrls,
    DateTime? createdAt,
  }) {
    return AuditAreaEntryModel(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      auditAreaId: auditAreaId ?? this.auditAreaId,
      responsiblePersonId: responsiblePersonId ?? this.responsiblePersonId,
      auditIssueIds: auditIssueIds ?? this.auditIssueIds,
      risk: risk ?? this.risk,
      observation: observation ?? this.observation,
      recommendation: recommendation ?? this.recommendation,
      deadlineDate: deadlineDate ?? this.deadlineDate,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'AuditAreaEntryModel(id: $id, reportId: $reportId, auditAreaId: $auditAreaId, risk: $risk)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AuditAreaEntryModel &&
        other.id == id &&
        other.reportId == reportId &&
        other.auditAreaId == auditAreaId &&
        other.responsiblePersonId == responsiblePersonId &&
        _listEquals(other.auditIssueIds, auditIssueIds) &&
        other.risk == risk &&
        other.observation == observation &&
        other.recommendation == recommendation &&
        other.deadlineDate == deadlineDate &&
        _listEquals(other.imageUrls, imageUrls) &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        reportId.hashCode ^
        auditAreaId.hashCode ^
        responsiblePersonId.hashCode ^
        auditIssueIds.hashCode ^
        risk.hashCode ^
        observation.hashCode ^
        recommendation.hashCode ^
        deadlineDate.hashCode ^
        imageUrls.hashCode ^
        createdAt.hashCode;
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
