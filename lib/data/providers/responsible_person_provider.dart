import 'dart:async';
import 'package:flutter/material.dart';
import 'package:surakshith/data/models/responsible_person_model.dart';
import 'package:surakshith/data/repositories/responsible_person_repository.dart';

class ResponsiblePersonProvider extends ChangeNotifier {
  ResponsiblePersonRepository? _responsiblePersonRepository;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isInitialized = false;
  List<ResponsiblePersonModel> _responsiblePersons = [];
  StreamSubscription<List<ResponsiblePersonModel>>? _responsiblePersonsSubscription;

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  // Initialize
  Future<void> init() async {
    _responsiblePersonRepository = ResponsiblePersonRepository();
    await _responsiblePersonRepository!.init();

    // Subscribe to real-time updates from Firestore
    _responsiblePersonsSubscription = _responsiblePersonRepository!.getResponsiblePersonsStream().listen(
      (responsiblePersons) {
        _responsiblePersons = responsiblePersons;
        _isInitialized = true;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error in responsible persons stream: $error');
        // Don't set error - offline mode will use cached data
      },
    );
  }

  @override
  void dispose() {
    _responsiblePersonsSubscription?.cancel();
    super.dispose();
  }

  // Get all responsible persons
  List<ResponsiblePersonModel> getAllResponsiblePersons() {
    return _responsiblePersons;
  }

  // Check for duplicate name (case-insensitive)
  bool isDuplicateName(String name, {String? excludeId}) {
    final persons = getAllResponsiblePersons();
    return persons.any((person) =>
      person.name.trim().toLowerCase() == name.trim().toLowerCase() &&
      person.id != excludeId
    );
  }

  // Add responsible person
  Future<bool> addResponsiblePerson({required String name}) async {
    if (_responsiblePersonRepository == null) {
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
        _setError('A responsible person with this name already exists');
        _setLoading(false);
        return false;
      }

      // Call repository
      // Firestore will automatically update the stream, which updates _responsiblePersons
      await _responsiblePersonRepository!.addResponsiblePerson(name: name);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to create responsible person: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update responsible person
  Future<bool> updateResponsiblePerson({
    required String id,
    required String name,
  }) async {
    if (_responsiblePersonRepository == null) {
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

      // Check for duplicate (excluding current responsible person)
      if (isDuplicateName(name, excludeId: id)) {
        _setError('A responsible person with this name already exists');
        _setLoading(false);
        return false;
      }

      // Call repository
      // Firestore will automatically update the stream, which updates _responsiblePersons
      await _responsiblePersonRepository!.updateResponsiblePerson(id: id, name: name);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update responsible person: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete responsible person
  Future<bool> deleteResponsiblePerson({required String id}) async {
    if (_responsiblePersonRepository == null) {
      _setError('Repository not initialized');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Call repository
      // Firestore will automatically update the stream, which updates _responsiblePersons
      await _responsiblePersonRepository!.deleteResponsiblePerson(id: id);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete responsible person: $e');
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
