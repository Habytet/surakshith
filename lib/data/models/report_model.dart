class ReportModel {
  final String id;
  final String clientId;
  final String projectId;
  final DateTime reportDate;
  final DateTime? createdAt;
  final String status; // 'draft', 'done'
  final List<String> imageUrls; // Firebase Storage image URLs
  final String? contactName; // Site contact person name

  ReportModel({
    required this.id,
    required this.clientId,
    required this.projectId,
    required this.reportDate,
    this.createdAt,
    this.status = 'draft',
    List<String>? imageUrls,
    this.contactName,
  }) : imageUrls = imageUrls ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'projectId': projectId,
      'reportDate': reportDate.millisecondsSinceEpoch,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'status': status,
      'imageUrls': imageUrls,
      'contactName': contactName,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'] ?? '',
      clientId: map['clientId'] ?? '',
      projectId: map['projectId'] ?? '',
      reportDate: map['reportDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['reportDate'])
          : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
      status: map['status'] ?? 'draft',
      imageUrls: map['imageUrls'] != null
          ? List<String>.from(map['imageUrls'])
          : [],
      contactName: map['contactName'],
    );
  }

  ReportModel copyWith({
    String? id,
    String? clientId,
    String? projectId,
    DateTime? reportDate,
    DateTime? createdAt,
    String? status,
    List<String>? imageUrls,
    String? contactName,
  }) {
    return ReportModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      projectId: projectId ?? this.projectId,
      reportDate: reportDate ?? this.reportDate,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      imageUrls: imageUrls ?? this.imageUrls,
      contactName: contactName ?? this.contactName,
    );
  }

  @override
  String toString() {
    return 'ReportModel(id: $id, clientId: $clientId, projectId: $projectId, reportDate: $reportDate, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ReportModel &&
        other.id == id &&
        other.clientId == clientId &&
        other.projectId == projectId &&
        other.reportDate == reportDate &&
        other.createdAt == createdAt &&
        other.status == status &&
        _listEquals(other.imageUrls, imageUrls) &&
        other.contactName == contactName;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        clientId.hashCode ^
        projectId.hashCode ^
        reportDate.hashCode ^
        createdAt.hashCode ^
        status.hashCode ^
        imageUrls.hashCode ^
        contactName.hashCode;
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
