// User roles in the system
enum UserRole {
  auditor, // You (the auditor)
  clientAdmin, // Hotel admin who can view reports and tasks
  clientStaff; // Hotel staff who execute tasks

  String toJson() => name;

  static UserRole fromJson(String json) {
    return UserRole.values.firstWhere(
      (e) => e.name == json,
      orElse: () => UserRole.clientStaff,
    );
  }
}

class UserModel {
  final String id;
  final String email;
  final DateTime? createdAt;
  final String uid;

  // NEW FIELDS for task management and client portal
  final UserRole role;
  final String? clientId; // For client users (admin/staff)
  final String? name; // Display name
  final String? phoneNumber; // Contact number
  final List<String> permissions; // Granular permissions
  final bool isActive; // Account status

  UserModel({
    required this.id,
    required this.email,
    this.createdAt,
    required this.uid,
    this.role = UserRole.auditor, // Default to auditor for backward compatibility
    this.clientId,
    this.name,
    this.phoneNumber,
    List<String>? permissions,
    this.isActive = true,
  }) : permissions = permissions ?? [];

  // Helper getters
  bool get isAuditor => role == UserRole.auditor;
  bool get isClientAdmin => role == UserRole.clientAdmin;
  bool get isClientStaff => role == UserRole.clientStaff;
  bool get isClientUser => isClientAdmin || isClientStaff;

  bool get hasClientAccess => clientId != null && clientId!.isNotEmpty;

  String get displayName => name ?? email.split('@').first;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'uid': uid,
      'role': role.toJson(),
      'clientId': clientId,
      'name': name,
      'phoneNumber': phoneNumber,
      'permissions': permissions,
      'isActive': isActive,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
      uid: map['uid'] ?? '',
      role: map['role'] != null
          ? UserRole.fromJson(map['role'])
          : UserRole.auditor, // Default for existing users
      clientId: map['clientId'],
      name: map['name'],
      phoneNumber: map['phoneNumber'],
      permissions: map['permissions'] != null
          ? List<String>.from(map['permissions'])
          : [],
      isActive: map['isActive'] ?? true,
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    DateTime? createdAt,
    String? uid,
    UserRole? role,
    String? clientId,
    String? name,
    String? phoneNumber,
    List<String>? permissions,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      uid: uid ?? this.uid,
      role: role ?? this.role,
      clientId: clientId ?? this.clientId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, role: $role, clientId: $clientId, name: $name, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.id == id &&
        other.email == email &&
        other.createdAt == createdAt &&
        other.uid == uid &&
        other.role == role &&
        other.clientId == clientId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        createdAt.hashCode ^
        uid.hashCode ^
        role.hashCode ^
        clientId.hashCode;
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
