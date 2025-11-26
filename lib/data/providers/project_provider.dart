import 'dart:async';
import 'package:flutter/material.dart';
import 'package:surakshith/data/models/project_model.dart';
import 'package:surakshith/data/repositories/project_repository.dart';

class ProjectProvider extends ChangeNotifier {
  ProjectRepository? _projectRepository;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isInitialized = false;
  String? _currentClientId;
  List<ProjectModel> _allProjects = [];
  StreamSubscription<List<ProjectModel>>? _projectsSubscription;

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  // Initialize
  Future<void> init() async {
    _projectRepository = ProjectRepository();
    await _projectRepository!.init();

    // Subscribe to real-time updates from Firestore (all projects across all clients)
    _projectsSubscription = _projectRepository!.getAllProjectsStream().listen(
      (projects) {
        _allProjects = projects;
        _isInitialized = true;
        notifyListeners();
      },
      onError: (error) {
        print('Error in projects stream: $error');
        // Don't set error - offline mode will use cached data
      },
    );
  }

  @override
  void dispose() {
    _projectsSubscription?.cancel();
    super.dispose();
  }

  // Set current client (for filtering and adding projects)
  Future<void> setCurrentClient(String clientId) async {
    _currentClientId = clientId;
    // Projects are already loaded via real-time stream - just notify
    notifyListeners();
  }

  // Get all projects for current client (filtered from the cached list)
  List<ProjectModel> getProjectsForCurrentClient() {
    if (!_isInitialized || _currentClientId == null) {
      return [];
    }
    return _allProjects
        .where((project) => project.clientId == _currentClientId)
        .toList();
  }

  // Get all projects from all clients
  List<ProjectModel> getAllProjects() {
    return _allProjects;
  }

  // Check for duplicate name (case-insensitive) within current client
  bool isDuplicateName(String name, {String? excludeId}) {
    final projects = getProjectsForCurrentClient();
    return projects.any((project) =>
      project.name.trim().toLowerCase() == name.trim().toLowerCase() &&
      project.id != excludeId
    );
  }

  // Add project
  Future<bool> addProject({
    required String name,
    String? contactName,
  }) async {
    if (_projectRepository == null) {
      _setError('Repository not initialized');
      return false;
    }

    if (_currentClientId == null) {
      _setError('No client selected');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Validation
      if (name.isEmpty) {
        _setError('Project name is required');
        _setLoading(false);
        return false;
      }

      // Check for duplicate
      if (isDuplicateName(name)) {
        _setError('A project with this name already exists');
        _setLoading(false);
        return false;
      }

      // Call repository
      // Firestore will automatically update the stream, which updates _allProjects
      await _projectRepository!.addProject(
        clientId: _currentClientId!,
        name: name,
        contactName: contactName,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to create project: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update project
  Future<bool> updateProject({
    required String id,
    required String name,
    String? contactName,
  }) async {
    if (_projectRepository == null) {
      _setError('Repository not initialized');
      return false;
    }

    if (_currentClientId == null) {
      _setError('No client selected');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Validation
      if (name.isEmpty) {
        _setError('Project name is required');
        _setLoading(false);
        return false;
      }

      // Check for duplicate (excluding current project)
      if (isDuplicateName(name, excludeId: id)) {
        _setError('A project with this name already exists');
        _setLoading(false);
        return false;
      }

      // Call repository
      // Firestore will automatically update the stream, which updates _allProjects
      await _projectRepository!.updateProject(
        clientId: _currentClientId!,
        id: id,
        name: name,
        contactName: contactName,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update project: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete project
  Future<bool> deleteProject({required String id}) async {
    if (_projectRepository == null) {
      _setError('Repository not initialized');
      return false;
    }

    if (_currentClientId == null) {
      _setError('No client selected');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Call repository
      // Firestore will automatically update the stream, which updates _allProjects
      await _projectRepository!.deleteProject(
        clientId: _currentClientId!,
        id: id,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete project: $e');
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
