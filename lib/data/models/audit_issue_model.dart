class AuditIssueModel {
  final String id;
  final String name;
  final DateTime? createdAt;
  final List<int> clauseNumbers; // Clause numbers 1-51

  AuditIssueModel({
    required this.id,
    required this.name,
    this.createdAt,
    List<int>? clauseNumbers,
  }) : clauseNumbers = clauseNumbers ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'clauseNumbers': clauseNumbers,
    };
  }

  factory AuditIssueModel.fromMap(Map<String, dynamic> map) {
    return AuditIssueModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
      clauseNumbers: map['clauseNumbers'] != null
          ? List<int>.from(map['clauseNumbers'])
          : [],
    );
  }

  AuditIssueModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    List<int>? clauseNumbers,
  }) {
    return AuditIssueModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      clauseNumbers: clauseNumbers ?? this.clauseNumbers,
    );
  }

  @override
  String toString() {
    return 'AuditIssueModel(id: $id, name: $name, createdAt: $createdAt, clauseNumbers: $clauseNumbers)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AuditIssueModel &&
        other.id == id &&
        other.name == name &&
        other.createdAt == createdAt &&
        _listEquals(other.clauseNumbers, clauseNumbers);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        createdAt.hashCode ^
        clauseNumbers.hashCode;
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
