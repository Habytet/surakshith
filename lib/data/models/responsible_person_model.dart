class ResponsiblePersonModel {
  final String id;
  final String name;
  final DateTime? createdAt;

  ResponsiblePersonModel({
    required this.id,
    required this.name,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }

  factory ResponsiblePersonModel.fromMap(Map<String, dynamic> map) {
    return ResponsiblePersonModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
    );
  }

  ResponsiblePersonModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return ResponsiblePersonModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ResponsiblePersonModel(id: $id, name: $name, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ResponsiblePersonModel &&
        other.id == id &&
        other.name == name &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ createdAt.hashCode;
  }
}
