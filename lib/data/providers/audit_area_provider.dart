import 'dart:async';
import 'package:flutter/material.dart';
import 'package:surakshith/data/models/audit_area_model.dart';
import 'package:surakshith/data/repositories/audit_area_repository.dart';

class AuditAreaProvider extends ChangeNotifier {
  AuditAreaRepository? _auditAreaRepository;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isInitialized = false;
  List<AuditAreaModel> _auditAreas = [];
  StreamSubscription<List<AuditAreaModel>>? _auditAreasSubscription;

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  // Initialize
  Future<void> init() async {
    _auditAreaRepository = AuditAreaRepository();
    await _auditAreaRepository!.init();

    // Subscribe to real-time updates from Firestore
    _auditAreasSubscription = _auditAreaRepository!.getAuditAreasStream().listen(
      (auditAreas) {
        _auditAreas = auditAreas;
        _isInitialized = true;
        notifyListeners();
      },
      onError: (error) {
        print('Error in audit areas stream: $error');
        // Don't set error - offline mode will use cached data
      },
    );
  }

  @override
  void dispose() {
    _auditAreasSubscription?.cancel();
    super.dispose();
  }

  // Get all audit areas
  List<AuditAreaModel> getAllAuditAreas() {
    return _auditAreas;
  }

  // Check for duplicate name (case-insensitive)
  bool isDuplicateName(String name, {String? excludeId}) {
    final auditAreas = getAllAuditAreas();
    return auditAreas.any((area) =>
      area.name.trim().toLowerCase() == name.trim().toLowerCase() &&
      area.id != excludeId
    );
  }

  // Add audit area
  Future<bool> addAuditArea({required String name}) async {
    if (_auditAreaRepository == null) {
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
        _setError('An audit area with this name already exists');
        _setLoading(false);
        return false;
      }

      // Call repository
      // Firestore will automatically update the stream, which updates _auditAreas
      await _auditAreaRepository!.addAuditArea(name: name);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to create audit area: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update audit area
  Future<bool> updateAuditArea({
    required String id,
    required String name,
  }) async {
    if (_auditAreaRepository == null) {
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

      // Check for duplicate (excluding current audit area)
      if (isDuplicateName(name, excludeId: id)) {
        _setError('An audit area with this name already exists');
        _setLoading(false);
        return false;
      }

      // Call repository
      // Firestore will automatically update the stream, which updates _auditAreas
      await _auditAreaRepository!.updateAuditArea(id: id, name: name);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update audit area: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete audit area
  Future<bool> deleteAuditArea({required String id}) async {
    if (_auditAreaRepository == null) {
      _setError('Repository not initialized');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Call repository
      // Firestore will automatically update the stream, which updates _auditAreas
      await _auditAreaRepository!.deleteAuditArea(id: id);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete audit area: $e');
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
