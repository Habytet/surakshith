import 'dart:async';
import 'package:flutter/material.dart';
import 'package:surakshith/data/models/audit_issue_model.dart';
import 'package:surakshith/data/repositories/audit_issue_repository.dart';

class AuditIssueProvider extends ChangeNotifier {
  AuditIssueRepository? _auditIssueRepository;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isInitialized = false;
  List<AuditIssueModel> _auditIssues = [];
  StreamSubscription<List<AuditIssueModel>>? _auditIssuesSubscription;

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  // Initialize
  Future<void> init() async {
    _auditIssueRepository = AuditIssueRepository();
    await _auditIssueRepository!.init();

    // Subscribe to real-time updates from Firestore
    _auditIssuesSubscription = _auditIssueRepository!.getAuditIssuesStream().listen(
      (auditIssues) {
        _auditIssues = auditIssues;
        _isInitialized = true;
        notifyListeners();
      },
      onError: (error) {
        print('Error in audit issues stream: $error');
        // Don't set error - offline mode will use cached data
      },
    );
  }

  @override
  void dispose() {
    _auditIssuesSubscription?.cancel();
    super.dispose();
  }

  // Get all audit issues
  List<AuditIssueModel> getAllAuditIssues() {
    return _auditIssues;
  }

  // Check for duplicate name (case-insensitive)
  bool isDuplicateName(String name, {String? excludeId}) {
    final issues = getAllAuditIssues();
    return issues.any((issue) =>
      issue.name.trim().toLowerCase() == name.trim().toLowerCase() &&
      issue.id != excludeId
    );
  }

  // Add audit issue
  Future<bool> addAuditIssue({
    required String name,
    List<int>? clauseNumbers,
  }) async {
    if (_auditIssueRepository == null) {
      _setError('Repository not initialized');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Validation
      if (name.isEmpty) {
        _setError('Name is required');
        _setLoading(false);
        return false;
      }

      // Check for duplicate
      if (isDuplicateName(name)) {
        _setError('An audit issue with this name already exists');
        _setLoading(false);
        return false;
      }

      // Call repository
      // Firestore will automatically update the stream, which updates _auditIssues
      await _auditIssueRepository!.addAuditIssue(
        name: name,
        clauseNumbers: clauseNumbers,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to create audit issue: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update audit issue
  Future<bool> updateAuditIssue({
    required String id,
    required String name,
    List<int>? clauseNumbers,
  }) async {
    if (_auditIssueRepository == null) {
      _setError('Repository not initialized');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Validation
      if (name.isEmpty) {
        _setError('Name is required');
        _setLoading(false);
        return false;
      }

      // Check for duplicate (excluding current audit issue)
      if (isDuplicateName(name, excludeId: id)) {
        _setError('An audit issue with this name already exists');
        _setLoading(false);
        return false;
      }

      // Call repository
      // Firestore will automatically update the stream, which updates _auditIssues
      await _auditIssueRepository!.updateAuditIssue(
        id: id,
        name: name,
        clauseNumbers: clauseNumbers,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update audit issue: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete audit issue
  Future<bool> deleteAuditIssue({required String id}) async {
    if (_auditIssueRepository == null) {
      _setError('Repository not initialized');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Call repository
      // Firestore will automatically update the stream, which updates _auditIssues
      await _auditIssueRepository!.deleteAuditIssue(id: id);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete audit issue: $e');
      _setLoading(false);
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
