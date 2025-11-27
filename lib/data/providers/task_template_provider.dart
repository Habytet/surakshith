import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:surakshith/data/models/task_template_model.dart';
import 'package:surakshith/data/repositories/task_template_repository.dart';
import 'package:surakshith/data/repositories/task_repository.dart';

/// Provider for managing task templates state
class TaskTemplateProvider with ChangeNotifier {
  final TaskTemplateRepository _templateRepository = TaskTemplateRepository();
  final TaskRepository _taskRepository = TaskRepository();

  List<TaskTemplateModel> _templates = [];
  List<TaskTemplateModel> _filteredTemplates = [];
  bool _isLoading = false;
  String? _error;

  // Filters
  String? _selectedClientId;
  RepeatFrequency? _selectedFrequency;
  bool _activeOnly = true;
  String _searchQuery = '';

  StreamSubscription<List<TaskTemplateModel>>? _templatesSubscription;

  // Getters
  List<TaskTemplateModel> get templates => _filteredTemplates;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedClientId => _selectedClientId;
  RepeatFrequency? get selectedFrequency => _selectedFrequency;
  bool get activeOnly => _activeOnly;
  String get searchQuery => _searchQuery;

  // ============================================
  // INITIALIZATION
  // ============================================

  /// Initialize and start listening to templates
  Future<void> initialize({String? clientId}) async {
    _selectedClientId = clientId;
    await _startListening();
  }

  /// Start listening to template changes
  Future<void> _startListening() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Cancel existing subscription
      await _templatesSubscription?.cancel();

      // Create appropriate stream based on filters
      Stream<List<TaskTemplateModel>> stream;

      if (_selectedClientId != null && _activeOnly) {
        stream = _templateRepository.getActiveTemplatesByClientStream(
          _selectedClientId!,
        );
      } else if (_selectedClientId != null) {
        stream = _templateRepository.getTemplatesByClientStream(
          _selectedClientId!,
        );
      } else {
        stream = _templateRepository.getAllTemplatesStream();
      }

      // Listen to stream
      _templatesSubscription = stream.listen(
        (templates) {
          _templates = templates;
          _applyFilters();
          _isLoading = false;
          _error = null;
          notifyListeners();
        },
        onError: (error) {
          _error = error.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Apply filters to templates
  void _applyFilters() {
    _filteredTemplates = _templates.where((template) {
      // Active filter
      if (_activeOnly && !template.isActive) return false;

      // Frequency filter
      if (_selectedFrequency != null && template.frequency != _selectedFrequency) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return template.title.toLowerCase().contains(query) ||
            template.description.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  // ============================================
  // FILTERS
  // ============================================

  /// Set client filter
  Future<void> setClientFilter(String? clientId) async {
    if (_selectedClientId != clientId) {
      _selectedClientId = clientId;
      await _startListening();
    }
  }

  /// Set frequency filter
  void setFrequencyFilter(RepeatFrequency? frequency) {
    _selectedFrequency = frequency;
    _applyFilters();
    notifyListeners();
  }

  /// Toggle active only filter
  void toggleActiveOnly() {
    _activeOnly = !_activeOnly;
    _startListening();
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _selectedFrequency = null;
    _searchQuery = '';
    _activeOnly = true;
    _applyFilters();
    notifyListeners();
  }

  // ============================================
  // CRUD OPERATIONS
  // ============================================

  /// Create a new template
  Future<String?> createTemplate(TaskTemplateModel template) async {
    try {
      final templateId = await _templateRepository.createTemplate(template);
      return templateId;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update a template
  Future<bool> updateTemplate(TaskTemplateModel template) async {
    try {
      final success = await _templateRepository.updateTemplate(template);
      if (!success) {
        _error = 'Failed to update template';
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Toggle template active status
  Future<bool> toggleTemplateActive(String templateId) async {
    try {
      final index = _templates.indexWhere((t) => t.id == templateId);
      if (index == -1) {
        _error = 'Template not found';
        notifyListeners();
        return false;
      }
      final template = _templates[index];
      final success = await _templateRepository.toggleTemplateActive(
        templateId,
        !template.isActive,
      );
      if (!success) {
        _error = 'Failed to toggle template';
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete a template
  Future<bool> deleteTemplate(String templateId) async {
    try {
      final success = await _templateRepository.deleteTemplate(templateId);
      if (!success) {
        _error = 'Failed to delete template';
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update default assignees for a template
  Future<bool> updateDefaultAssignees(
    String templateId,
    List<String> assignees,
  ) async {
    try {
      final success = await _templateRepository.updateDefaultAssignees(
        templateId,
        assignees,
      );
      if (!success) {
        _error = 'Failed to update assignees';
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // TASK GENERATION
  // ============================================

  /// Generate tasks from all active templates
  Future<int> generateDailyTasks() async {
    try {
      final templatesToGenerate = await _templateRepository.getTemplatesForToday();
      int tasksCreated = 0;

      for (final template in templatesToGenerate) {
        // Generate task for each default assignee
        for (final _ in template.defaultAssignees) {
          final task = template.generateTask();
          final taskId = await _taskRepository.createTask(task);

          if (taskId != null) {
            tasksCreated++;
          }
        }

        // Update last generated timestamp
        await _templateRepository.updateLastGenerated(
          template.id,
          DateTime.now(),
        );
      }

      return tasksCreated;
    } catch (e) {
      _error = 'Failed to generate tasks: $e';
      notifyListeners();
      return 0;
    }
  }

  /// Generate task from specific template
  Future<String?> generateTaskFromTemplate({
    required String templateId,
    DateTime? dueDate,
    List<String>? assignees,
  }) async {
    try {
      final template = await _templateRepository.getTemplateById(templateId);
      if (template == null) {
        _error = 'Template not found';
        notifyListeners();
        return null;
      }

      final task = template.generateTask(
        dueDate: dueDate,
        assignees: assignees,
      );

      final taskId = await _taskRepository.createTask(task);
      return taskId;
    } catch (e) {
      _error = 'Failed to generate task: $e';
      notifyListeners();
      return null;
    }
  }

  // ============================================
  // HELPERS
  // ============================================

  /// Get template by ID
  TaskTemplateModel? getTemplateById(String templateId) {
    final index = _templates.indexWhere((t) => t.id == templateId);
    return index != -1 ? _templates[index] : null;
  }

  /// Get templates by client
  List<TaskTemplateModel> getTemplatesByClient(String clientId) {
    return _templates.where((t) => t.clientId == clientId).toList();
  }

  /// Get active templates count
  int get activeTemplatesCount {
    return _templates.where((t) => t.isActive).length;
  }

  /// Get templates by frequency
  List<TaskTemplateModel> getTemplatesByFrequency(RepeatFrequency frequency) {
    return _templates.where((t) => t.frequency == frequency).toList();
  }

  // ============================================
  // CLEANUP
  // ============================================

  @override
  void dispose() {
    _templatesSubscription?.cancel();
    super.dispose();
  }
}
