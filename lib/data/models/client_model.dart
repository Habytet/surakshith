class ClientModel {
  final String id;
  final String name;
  final String contactNumber;
  final DateTime? createdAt;
  final String? fssaiNumber;

  ClientModel({
    required this.id,
    required this.name,
    required this.contactNumber,
    this.createdAt,
    this.fssaiNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contactNumber': contactNumber,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'fssaiNumber': fssaiNumber,
    };
  }

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      contactNumber: map['contactNumber'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
      fssaiNumber: map['fssaiNumber'],
    );
  }

  ClientModel copyWith({
    String? id,
    String? name,
    String? contactNumber,
    DateTime? createdAt,
    String? fssaiNumber,
  }) {
    return ClientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      contactNumber: contactNumber ?? this.contactNumber,
      createdAt: createdAt ?? this.createdAt,
      fssaiNumber: fssaiNumber ?? this.fssaiNumber,
    );
  }

  @override
  String toString() {
    return 'ClientModel(id: $id, name: $name, contactNumber: $contactNumber, createdAt: $createdAt, fssaiNumber: $fssaiNumber)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ClientModel &&
        other.id == id &&
        other.name == name &&
        other.contactNumber == contactNumber &&
        other.createdAt == createdAt &&
        other.fssaiNumber == fssaiNumber;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        contactNumber.hashCode ^
        createdAt.hashCode ^
        fssaiNumber.hashCode;
  }
}
