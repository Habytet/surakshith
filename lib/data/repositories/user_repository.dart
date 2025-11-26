import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:surakshith/data/models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Reference to users collection
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Initialize repository (no longer needed, but keeping for API compatibility)
  Future<void> init() async {
    // Firestore doesn't need initialization
    // Offline persistence is enabled globally in main.dart
  }

  // Get all users as a Stream (real-time updates!)
  Stream<List<UserModel>> getUsersStream() {
    return _usersCollection.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) =>
                  UserModel.fromMap(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  // Get all users as a one-time fetch (for compatibility)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _usersCollection.get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If offline, Firestore will return cached data automatically
      rethrow;
    }
  }

  // Add user (creates in Firebase Auth and stores in Firestore)
  // Firestore offline persistence handles local caching automatically
  Future<void> addUser({
    required String email,
    required String password,
    UserRole role = UserRole.auditor,
    String? clientId,
    String? name,
    String? phoneNumber,
    List<String>? permissions,
  }) async {
    // Create user in Firebase Authentication
    UserCredential userCredential =
        await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = UserModel(
      id: userCredential.user!.uid,
      email: email,
      createdAt: DateTime.now(),
      uid: userCredential.user!.uid,
      role: role,
      clientId: clientId,
      name: name,
      phoneNumber: phoneNumber,
      permissions: permissions ?? [],
      isActive: true,
    );

    // Write to Firestore
    // If offline, this will be cached locally and synced automatically when online
    await _usersCollection.doc(user.uid).set(user.toMap());
  }

  // Update user (updates in Firestore)
  // Firestore offline persistence handles local caching automatically
  Future<void> updateUser({
    required String uid,
    String? email,
    UserRole? role,
    String? clientId,
    String? name,
    String? phoneNumber,
    List<String>? permissions,
    bool? isActive,
  }) async {
    final updateData = <String, dynamic>{};

    if (email != null) updateData['email'] = email;
    if (role != null) updateData['role'] = role.toJson();
    if (clientId != null) updateData['clientId'] = clientId;
    if (name != null) updateData['name'] = name;
    if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
    if (permissions != null) updateData['permissions'] = permissions;
    if (isActive != null) updateData['isActive'] = isActive;

    // Update in Firestore
    // If offline, this will be cached locally and synced automatically when online
    if (updateData.isNotEmpty) {
      await _usersCollection.doc(uid).update(updateData);
    }
  }

  // Delete user (deletes from Firestore)
  // Firestore offline persistence handles local caching automatically
  Future<void> deleteUser({required String uid}) async {
    // Delete from Firestore
    // If offline, this will be cached locally and synced automatically when online
    await _usersCollection.doc(uid).delete();
  }

  // Get user by UID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      rethrow;
    }
  }

  // Get user by UID as Stream (real-time)
  Stream<UserModel?> getUserByIdStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final snapshot = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return UserModel.fromMap(
            snapshot.docs.first.data() as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      print('Error getting user by email: $e');
      rethrow;
    }
  }

  // Get users by role
  Future<List<UserModel>> getUsersByRole(UserRole role) async {
    try {
      final snapshot = await _usersCollection
          .where('role', isEqualTo: role.toJson())
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting users by role: $e');
      rethrow;
    }
  }

  // Get users by role as Stream (real-time)
  Stream<List<UserModel>> getUsersByRoleStream(UserRole role) {
    return _usersCollection
        .where('role', isEqualTo: role.toJson())
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get users by client (for client admins and staff)
  Future<List<UserModel>> getUsersByClient(String clientId) async {
    try {
      final snapshot = await _usersCollection
          .where('clientId', isEqualTo: clientId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting users by client: $e');
      rethrow;
    }
  }

  // Get users by client as Stream (real-time)
  Stream<List<UserModel>> getUsersByClientStream(String clientId) {
    return _usersCollection
        .where('clientId', isEqualTo: clientId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get client users by role (admins or staff)
  Future<List<UserModel>> getClientUsersByRole({
    required String clientId,
    required UserRole role,
  }) async {
    try {
      final snapshot = await _usersCollection
          .where('clientId', isEqualTo: clientId)
          .where('role', isEqualTo: role.toJson())
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting client users by role: $e');
      rethrow;
    }
  }

  // Get all auditors
  Future<List<UserModel>> getAuditors() async {
    return getUsersByRole(UserRole.auditor);
  }

  // Get all auditors as Stream
  Stream<List<UserModel>> getAuditorsStream() {
    return getUsersByRoleStream(UserRole.auditor);
  }

  // Get all client admins
  Future<List<UserModel>> getClientAdmins() async {
    return getUsersByRole(UserRole.clientAdmin);
  }

  // Get all client staff
  Future<List<UserModel>> getClientStaff() async {
    return getUsersByRole(UserRole.clientStaff);
  }

  // Get all active users
  Future<List<UserModel>> getActiveUsers() async {
    try {
      final snapshot =
          await _usersCollection.where('isActive', isEqualTo: true).get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting active users: $e');
      rethrow;
    }
  }

  // Get all active users as Stream
  Stream<List<UserModel>> getActiveUsersStream() {
    return _usersCollection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get all inactive users
  Future<List<UserModel>> getInactiveUsers() async {
    try {
      final snapshot =
          await _usersCollection.where('isActive', isEqualTo: false).get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting inactive users: $e');
      rethrow;
    }
  }

  // Activate user
  Future<void> activateUser(String uid) async {
    await _usersCollection.doc(uid).update({'isActive': true});
  }

  // Deactivate user
  Future<void> deactivateUser(String uid) async {
    await _usersCollection.doc(uid).update({'isActive': false});
  }

  // Update user role
  Future<void> updateUserRole({
    required String uid,
    required UserRole role,
  }) async {
    await _usersCollection.doc(uid).update({
      'role': role.toJson(),
    });
  }

  // Assign user to client
  Future<void> assignUserToClient({
    required String uid,
    required String clientId,
  }) async {
    await _usersCollection.doc(uid).update({
      'clientId': clientId,
    });
  }

  // Remove user from client
  Future<void> removeUserFromClient(String uid) async {
    await _usersCollection.doc(uid).update({
      'clientId': null,
    });
  }

  // Update user permissions
  Future<void> updateUserPermissions({
    required String uid,
    required List<String> permissions,
  }) async {
    await _usersCollection.doc(uid).update({
      'permissions': permissions,
    });
  }

  // Add permission to user
  Future<void> addPermission({
    required String uid,
    required String permission,
  }) async {
    final user = await getUserById(uid);
    if (user != null) {
      final permissions = List<String>.from(user.permissions);
      if (!permissions.contains(permission)) {
        permissions.add(permission);
        await updateUserPermissions(uid: uid, permissions: permissions);
      }
    }
  }

  // Remove permission from user
  Future<void> removePermission({
    required String uid,
    required String permission,
  }) async {
    final user = await getUserById(uid);
    if (user != null) {
      final permissions = List<String>.from(user.permissions);
      permissions.remove(permission);
      await updateUserPermissions(uid: uid, permissions: permissions);
    }
  }

  // Check if user has permission
  Future<bool> hasPermission({
    required String uid,
    required String permission,
  }) async {
    final user = await getUserById(uid);
    return user?.permissions.contains(permission) ?? false;
  }

  // No longer need manual sync methods!
  // Firestore handles all syncing automatically with offline persistence
}
