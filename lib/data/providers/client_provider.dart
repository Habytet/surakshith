import 'dart:async';
import 'package:flutter/material.dart';
import 'package:surakshith/data/models/client_model.dart';
import 'package:surakshith/data/repositories/client_repository.dart';

class ClientProvider extends ChangeNotifier {
  ClientRepository? _clientRepository;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isInitialized = false;
  List<ClientModel> _clients = [];
  StreamSubscription<List<ClientModel>>? _clientsSubscription;

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  // Initialize
  Future<void> init() async {
    _clientRepository = ClientRepository();
    await _clientRepository!.init();

    // Subscribe to real-time updates from Firestore
    _clientsSubscription = _clientRepository!.getClientsStream().listen(
      (clients) {
        _clients = clients;
        _isInitialized = true;
        notifyListeners();
      },
      onError: (error) {
        print('Error in clients stream: $error');
        // Don't set error - offline mode will use cached data
      },
    );
  }

  @override
  void dispose() {
    _clientsSubscription?.cancel();
    super.dispose();
  }

  // Get all clients (from local cache, updated automatically via stream)
  List<ClientModel> getAllClients() {
    return _clients;
  }

  // Check for duplicate name (case-insensitive)
  bool isDuplicateName(String name, {String? excludeId}) {
    final clients = getAllClients();
    return clients.any((client) =>
      client.name.trim().toLowerCase() == name.trim().toLowerCase() &&
      client.id != excludeId
    );
  }

  // Add client
  Future<bool> addClient({
    required String name,
    required String contactNumber,
    String? fssaiNumber,
  }) async {
    if (_clientRepository == null) {
      _setError('Repository not initialized');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Validation
      if (name.isEmpty) {
        _setError('Client name is required');
        _setLoading(false);
        return false;
      }

      if (contactNumber.isEmpty) {
        _setError('Contact number is required');
        _setLoading(false);
        return false;
      }

      // Check for duplicate
      if (isDuplicateName(name)) {
        _setError('A client with this name already exists');
        _setLoading(false);
        return false;
      }

      // Call repository
      // Firestore will automatically update the stream, which updates _clients
      await _clientRepository!.addClient(
        name: name,
        contactNumber: contactNumber,
        fssaiNumber: fssaiNumber,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to create client: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update client
  Future<bool> updateClient({
    required String id,
    required String name,
    required String contactNumber,
    String? fssaiNumber,
  }) async {
    if (_clientRepository == null) {
      _setError('Repository not initialized');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Validation
      if (name.isEmpty) {
        _setError('Client name is required');
        _setLoading(false);
        return false;
      }

      if (contactNumber.isEmpty) {
        _setError('Contact number is required');
        _setLoading(false);
        return false;
      }

      // Check for duplicate (excluding current client)
      if (isDuplicateName(name, excludeId: id)) {
        _setError('A client with this name already exists');
        _setLoading(false);
        return false;
      }

      // Call repository
      // Firestore will automatically update the stream, which updates _clients
      await _clientRepository!.updateClient(
        id: id,
        name: name,
        contactNumber: contactNumber,
        fssaiNumber: fssaiNumber,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update client: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete client
  Future<bool> deleteClient({required String id}) async {
    if (_clientRepository == null) {
      _setError('Repository not initialized');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Call repository
      // Firestore will automatically update the stream, which updates _clients
      await _clientRepository!.deleteClient(id: id);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete client: $e');
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
