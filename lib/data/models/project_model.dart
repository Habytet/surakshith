class ProjectModel {
  final String id;
  final String name;
  final String clientId;
  final String? contactName;
  final DateTime? createdAt;

  ProjectModel({
    required this.id,
    required this.name,
    required this.clientId,
    this.contactName,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'clientId': clientId,
      'contactName': contactName,
      'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      clientId: map['clientId'] ?? '',
      contactName: map['contactName'],
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
    );
  }

  ProjectModel copyWith({
    String? id,
    String? name,
    String? clientId,
    String? contactName,
    DateTime? createdAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      clientId: clientId ?? this.clientId,
      contactName: contactName ?? this.contactName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ProjectModel(id: $id, name: $name, clientId: $clientId, contactName: $contactName, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProjectModel &&
        other.id == id &&
        other.name == name &&
        other.clientId == clientId &&
        other.contactName == contactName &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        clientId.hashCode ^
        contactName.hashCode ^
        createdAt.hashCode;
  }
}
