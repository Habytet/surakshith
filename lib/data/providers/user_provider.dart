import 'dart:async';
import 'package:flutter/material.dart';
import 'package:surakshith/data/models/user_model.dart';
import 'package:surakshith/data/repositories/user_repository.dart';

class UserProvider extends ChangeNotifier {
  UserRepository? _userRepository;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isInitialized = false;
  List<UserModel> _users = [];
  StreamSubscription<List<UserModel>>? _usersSubscription;

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  // Initialize
  Future<void> init() async {
    _userRepository = UserRepository();
    await _userRepository!.init();

    // Subscribe to real-time updates from Firestore
    _usersSubscription = _userRepository!.getUsersStream().listen(
      (users) {
        _users = users;
        _isInitialized = true;
        notifyListeners();
      },
      onError: (error) {
        print('Error in users stream: $error');
        // Don't set error - offline mode will use cached data
      },
    );
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    super.dispose();
  }

  // Get all users (from local cache, updated automatically via stream)
  List<UserModel> getAllUsers() {
    return _users;
  }

  // Add user
  Future<bool> addUser({
    required String email,
    required String password,
    UserRole role = UserRole.auditor,
    String? clientId,
    String? name,
    String? phoneNumber,
    List<String>? permissions,
  }) async {
    if (_userRepository == null) {
      _setError('Repository not initialized');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Validation
      if (email.isEmpty) {
        _setError('Email is required');
        _setLoading(false);
        return false;
      }

      if (!email.contains('@')) {
        _setError('Please enter a valid email');
        _setLoading(false);
        return false;
      }

      if (password.isEmpty) {
        _setError('Password is required');
        _setLoading(false);
        return false;
      }

      if (password.length < 6) {
        _setError('Password must be at least 6 characters');
        _setLoading(false);
        return false;
      }

      // Validate client users have clientId
      if ((role == UserRole.clientAdmin || role == UserRole.clientStaff) &&
          (clientId == null || clientId.isEmpty)) {
        _setError('Client users must have a clientId');
        _setLoading(false);
        return false;
      }

      // Call repository
      // Firestore will automatically update the stream, which updates _users
      await _userRepository!.addUser(
        email: email,
        password: password,
        role: role,
        clientId: clientId,
        name: name,
        phoneNumber: phoneNumber,
        permissions: permissions,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to create user: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update user
  Future<bool> updateUser({
    required String uid,
    String? email,
    UserRole? role,
    String? clientId,
    String? name,
    String? phoneNumber,
    List<String>? permissions,
    bool? isActive,
  }) async {
    if (_userRepository == null) {
      _setError('Repository not initialized');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Validation for email if provided
      if (email != null && email.isEmpty) {
        _setError('Email cannot be empty');
        _setLoading(false);
        return false;
      }

      if (email != null && !email.contains('@')) {
        _setError('Please enter a valid email');
        _setLoading(false);
        return false;
      }

      // Call repository
      // Firestore will automatically update the stream, which updates _users
      await _userRepository!.updateUser(
        uid: uid,
        email: email,
        role: role,
        clientId: clientId,
        name: name,
        phoneNumber: phoneNumber,
        permissions: permissions,
        isActive: isActive,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update user: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete user
  Future<bool> deleteUser({required String uid}) async {
    if (_userRepository == null) {
      _setError('Repository not initialized');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Call repository
      // Firestore will automatically update the stream, which updates _users
      await _userRepository!.deleteUser(uid: uid);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete user: $e');
      _setLoading(false);
      return false;
    }
  }

  // Get users by role
  List<UserModel> getUsersByRole(UserRole role) {
    return _users.where((user) => user.role == role && user.isActive).toList();
  }

  // Get users by client
  List<UserModel> getUsersByClient(String clientId) {
    return _users
        .where((user) => user.clientId == clientId && user.isActive)
        .toList();
  }

  // Get user by ID
  UserModel? getUserById(String uid) {
    try {
      return _users.firstWhere((user) => user.uid == uid);
    } catch (e) {
      return null;
    }
  }

  // Get user by email
  UserModel? getUserByEmail(String email) {
    try {
      return _users.firstWhere((user) => user.email == email);
    } catch (e) {
      return null;
    }
  }

  // Get all auditors
  List<UserModel> getAuditors() {
    return getUsersByRole(UserRole.auditor);
  }

  // Get all client admins
  List<UserModel> getClientAdmins() {
    return getUsersByRole(UserRole.clientAdmin);
  }

  // Get all client staff
  List<UserModel> getClientStaff() {
    return getUsersByRole(UserRole.clientStaff);
  }

  // Get client users (both admins and staff)
  List<UserModel> getClientUsers(String clientId) {
    return getUsersByClient(clientId);
  }

  // Get client admins for specific client
  List<UserModel> getClientAdminsByClient(String clientId) {
    return _users
        .where((user) =>
            user.clientId == clientId &&
            user.role == UserRole.clientAdmin &&
            user.isActive)
        .toList();
  }

  // Get client staff for specific client
  List<UserModel> getClientStaffByClient(String clientId) {
    return _users
        .where((user) =>
            user.clientId == clientId &&
            user.role == UserRole.clientStaff &&
            user.isActive)
        .toList();
  }

  // Get active users
  List<UserModel> getActiveUsers() {
    return _users.where((user) => user.isActive).toList();
  }

  // Get inactive users
  List<UserModel> getInactiveUsers() {
    return _users.where((user) => !user.isActive).toList();
  }

  // Update user role
  Future<bool> updateUserRole({
    required String uid,
    required UserRole role,
  }) async {
    if (_userRepository == null) {
      _setError('Repository not initialized');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _userRepository!.updateUserRole(uid: uid, role: role);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update user role: $e');
      _setLoading(false);
      return false;
    }
  }

  // Assign user to client
  Future<bool> assignUserToClient({
    required String uid,
    required String clientId,
  }) async {
    if (_userRepository == null) {
      _setError('Repository not initialized');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _userRepository!.assignUserToClient(uid: uid, clientId: clientId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to assign user to client: $e');
      _setLoading(false);
      return false;
    }
  }

  // Remove user from client
  Future<bool> removeUserFromClient(String uid) async {
    if (_userRepository == null) {
      _setError('Repository not initialized');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _userRepository!.removeUserFromClient(uid);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to remove user from client: $e');
      _setLoading(false);
      return false;
    }
  }

  // Activate user
  Future<bool> activateUser(String uid) async {
    if (_userRepository == null) {
      _setError('Repository not initialized');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _userRepository!.activateUser(uid);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to activate user: $e');
      _setLoading(false);
      return false;
    }
  }

  // Deactivate user
  Future<bool> deactivateUser(String uid) async {
    if (_userRepository == null) {
      _setError('Repository not initialized');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _userRepository!.deactivateUser(uid);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to deactivate user: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update user permissions
  Future<bool> updateUserPermissions({
    required String uid,
    required List<String> permissions,
  }) async {
    if (_userRepository == null) {
      _setError('Repository not initialized');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _userRepository!.updateUserPermissions(
        uid: uid,
        permissions: permissions,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update user permissions: $e');
      _setLoading(false);
      return false;
    }
  }

  // Add permission to user
  Future<bool> addPermission({
    required String uid,
    required String permission,
  }) async {
    if (_userRepository == null) {
      _setError('Repository not initialized');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _userRepository!.addPermission(uid: uid, permission: permission);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add permission: $e');
      _setLoading(false);
      return false;
    }
  }

  // Remove permission from user
  Future<bool> removePermission({
    required String uid,
    required String permission,
  }) async {
    if (_userRepository == null) {
      _setError('Repository not initialized');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _userRepository!.removePermission(uid: uid, permission: permission);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to remove permission: $e');
      _setLoading(false);
      return false;
    }
  }

  // Check if user has permission
  Future<bool> hasPermission({
    required String uid,
    required String permission,
  }) async {
    if (_userRepository == null) {
      return false;
    }

    try {
      return await _userRepository!.hasPermission(
        uid: uid,
        permission: permission,
      );
    } catch (e) {
      return false;
    }
  }

  // No longer need manual sync!
  // Firestore real-time listeners + offline persistence handle everything automatically

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
  }
}
