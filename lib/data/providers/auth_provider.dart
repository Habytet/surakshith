import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:surakshith/data/repositories/auth_repository.dart';
import 'package:surakshith/services/fcm_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  bool _isLoading = false;
  String _errorMessage = '';
  User? _currentUser;

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  // Initialize
  void init() {
    _currentUser = _authRepository.getCurrentUser();

    // Listen to auth state changes
    _authRepository.authStateChanges().listen((User? user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Validation
      if (email.isEmpty) {
        _setError('Email is required');
        _setLoading(false);
        return false;
      }

      if (password.isEmpty) {
        _setError('Password is required');
        _setLoading(false);
        return false;
      }

      if (!email.contains('@')) {
        _setError('Please enter a valid email');
        _setLoading(false);
        return false;
      }

      // Call repository
      final user = await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _currentUser = user;

      // Save FCM token to Firestore after successful login
      if (user != null) {
        try {
          await FCMService().saveTokenToFirestore(user.uid);
        } catch (e) {
          // Don't fail login if FCM token save fails
          debugPrint('Failed to save FCM token: $e');
        }
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    try {
      // Remove FCM token from Firestore before signing out
      if (_currentUser != null) {
        await FCMService().removeTokenFromFirestore(_currentUser!.uid);
      }

      await _authRepository.signOut();
      _currentUser = null;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword({required String email}) async {
    _setLoading(true);
    _clearError();

    try {
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

      await _authRepository.sendPasswordResetEmail(email: email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

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
