import 'dart:async';
import 'package:flutter/material.dart';
import 'package:surakshith/data/models/task_model.dart';
import 'package:surakshith/data/repositories/task_repository.dart';

class TaskProvider extends ChangeNotifier {
  final TaskRepository _taskRepository = TaskRepository();

  bool _isLoading = false;
  String _errorMessage = '';
  List<TaskModel> _tasks = [];
  StreamSubscription<List<TaskModel>>? _tasksSubscription;

  // Filters
  String? _selectedClientId;
  String? _selectedAssignee;
  TaskStatus? _selectedStatus;
  TaskSource? _selectedSource;
  TaskPriority? _selectedPriority;
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<TaskModel> get allTasks => _tasks;

  String? get selectedClientId => _selectedClientId;
  String? get selectedAssignee => _selectedAssignee;
  TaskStatus? get selectedStatus => _selectedStatus;
  TaskSource? get selectedSource => _selectedSource;
  TaskPriority? get selectedPriority => _selectedPriority;
  String get searchQuery => _searchQuery;

  // Get filtered tasks based on current filters
  List<TaskModel> get tasks {
    var filteredTasks = List<TaskModel>.from(_tasks);

    // Apply client filter
    if (_selectedClientId != null) {
      filteredTasks = filteredTasks
          .where((task) => task.clientId == _selectedClientId)
          .toList();
    }

    // Apply assignee filter
    if (_selectedAssignee != null) {
      filteredTasks = filteredTasks
          .where((task) => task.assignedTo.contains(_selectedAssignee))
          .toList();
    }

    // Apply status filter
    if (_selectedStatus != null) {
      filteredTasks = filteredTasks
          .where((task) => task.status == _selectedStatus)
          .toList();
    }

    // Apply source filter
    if (_selectedSource != null) {
      filteredTasks = filteredTasks
          .where((task) => task.source == _selectedSource)
          .toList();
    }

    // Apply priority filter
    if (_selectedPriority != null) {
      filteredTasks = filteredTasks
          .where((task) => task.priority == _selectedPriority)
          .toList();
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredTasks = filteredTasks.where((task) {
        return task.title.toLowerCase().contains(query) ||
            task.description.toLowerCase().contains(query) ||
            task.staffComments.toLowerCase().contains(query) ||
            task.adminComments.toLowerCase().contains(query);
      }).toList();
    }

    return filteredTasks;
  }

  // Get tasks by various criteria
  List<TaskModel> getTasksByClient(String clientId) {
    return _tasks.where((task) => task.clientId == clientId).toList();
  }

  List<TaskModel> getTasksByAssignee(String userEmail) {
    return _tasks
        .where((task) => task.assignedTo.contains(userEmail))
        .toList();
  }

  List<TaskModel> getTasksByStatus(TaskStatus status) {
    return _tasks.where((task) => task.status == status).toList();
  }

  List<TaskModel> getTasksBySource(TaskSource source) {
    return _tasks.where((task) => task.source == source).toList();
  }

  List<TaskModel> getRepetitiveTasks() {
    return _tasks.where((task) => task.isRepetitive).toList();
  }

  List<TaskModel> getOverdueTasks() {
    return _tasks.where((task) => task.isOverdue).toList();
  }

  List<TaskModel> getTasksForReview() {
    return _tasks.where((task) => task.isPendingReview).toList();
  }

  // Get task statistics
  Map<String, int> getTaskStatistics({String? clientId}) {
    final tasksToAnalyze = clientId != null
        ? _tasks.where((task) => task.clientId == clientId).toList()
        : _tasks;

    return {
      'total': tasksToAnalyze.length,
      'assigned':
          tasksToAnalyze.where((task) => task.isAssigned).length,
      'inProgress':
          tasksToAnalyze.where((task) => task.isInProgress).length,
      'pendingReview':
          tasksToAnalyze.where((task) => task.isPendingReview).length,
      'completed':
          tasksToAnalyze.where((task) => task.isCompleted).length,
      'incomplete':
          tasksToAnalyze.where((task) => task.isIncomplete).length,
      'overdue': tasksToAnalyze.where((task) => task.isOverdue).length,
    };
  }

  // Initialize and listen to real-time updates
  Future<void> init() async {
    _setLoading(true);
    try {
      await _taskRepository.init();

      // Listen to real-time task updates
      _tasksSubscription = _taskRepository.getAllTasksStream().listen(
        (tasks) {
          _tasks = tasks;
          _setLoading(false);
          notifyListeners();
        },
        onError: (error) {
          _setError('Error listening to tasks: $error');
          _setLoading(false);
        },
      );
    } catch (e) {
      _setError('Error initializing task provider: $e');
      _setLoading(false);
    }
  }

  // Listen to tasks for specific client
  void listenToClientTasks(String clientId) {
    _tasksSubscription?.cancel();
    _tasksSubscription = _taskRepository.getTasksByClientStream(clientId).listen(
      (tasks) {
        _tasks = tasks;
        notifyListeners();
      },
      onError: (error) {
        _setError('Error listening to client tasks: $error');
      },
    );
  }

  // Listen to tasks for specific assignee
  void listenToAssigneeTasks(String userEmail) {
    _tasksSubscription?.cancel();
    _tasksSubscription =
        _taskRepository.getTasksByAssigneeStream(userEmail).listen(
      (tasks) {
        _tasks = tasks;
        notifyListeners();
      },
      onError: (error) {
        _setError('Error listening to assignee tasks: $error');
      },
    );
  }

  // CREATE - Create a task
  Future<String?> createTask(TaskModel task) async {
    _setLoading(true);
    _clearError();

    try {
      if (!task.isValid) {
        _setError('Invalid task: Title and assignees are required');
        _setLoading(false);
        return null;
      }

      final taskId = await _taskRepository.createTask(task);
      _setLoading(false);
      return taskId;
    } catch (e) {
      _setError('Error creating task: $e');
      _setLoading(false);
      return null;
    }
  }

  // CREATE - Create task from audit entry
  Future<String?> createTaskFromAudit({
    required String auditReportId,
    required String auditEntryId,
    required String auditAreaId,
    required List<String> auditIssueIds,
    required String title,
    required String description,
    required List<String> assignedTo,
    required String clientId,
    required String projectId,
    required String createdBy,
    required DateTime dueDate,
    required String risk, // low, medium, high
    List<String>? images,
  }) async {
    final task = TaskModel(
      id: '', // Will be generated by Firestore
      title: title,
      description: description,
      source: TaskSource.audit,
      auditReportId: auditReportId,
      auditEntryId: auditEntryId,
      auditAreaId: auditAreaId,
      auditIssueIds: auditIssueIds,
      createdBy: createdBy,
      assignedTo: assignedTo,
      clientId: clientId,
      projectId: projectId,
      createdAt: DateTime.now(),
      assignedDate: DateTime.now(),
      dueDate: dueDate,
      type: TaskType.oneTime,
      priority: TaskPriority.fromRisk(risk),
      status: TaskStatus.assigned,
      staffImages: images ?? [],
    );

    return await createTask(task);
  }

  // CREATE - Create standalone task
  Future<String?> createStandaloneTask({
    required String title,
    required String description,
    required List<String> assignedTo,
    required String clientId,
    required String projectId,
    required String createdBy,
    required DateTime assignedDate,
    required DateTime dueDate,
    required TaskType type,
    String? repeatFrequency,
    TaskPriority priority = TaskPriority.medium,
  }) async {
    final task = TaskModel(
      id: '', // Will be generated by Firestore
      title: title,
      description: description,
      source: TaskSource.standalone,
      createdBy: createdBy,
      assignedTo: assignedTo,
      clientId: clientId,
      projectId: projectId,
      createdAt: DateTime.now(),
      assignedDate: assignedDate,
      dueDate: dueDate,
      type: type,
      repeatFrequency: repeatFrequency,
      priority: priority,
      status: TaskStatus.assigned,
    );

    return await createTask(task);
  }

  // CREATE - Batch create tasks for multiple assignees
  Future<List<String>> createTasksForMultipleAssignees({
    required TaskModel baseTask,
    required List<String> assignees,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final tasks = assignees.map((assignee) {
        return baseTask.copyWith(assignedTo: [assignee]);
      }).toList();

      final taskIds = await _taskRepository.createTaskBatch(tasks);
      _setLoading(false);
      return taskIds;
    } catch (e) {
      _setError('Error creating tasks for multiple assignees: $e');
      _setLoading(false);
      return [];
    }
  }

  // READ - Get task by ID
  Future<TaskModel?> getTaskById(String taskId) async {
    try {
      return await _taskRepository.getTaskById(taskId);
    } catch (e) {
      _setError('Error getting task: $e');
      return null;
    }
  }

  // UPDATE - Update task
  Future<bool> updateTask(TaskModel task) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _taskRepository.updateTask(task);
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Error updating task: $e');
      _setLoading(false);
      return false;
    }
  }

  // UPDATE - Start task (staff action)
  Future<bool> startTask(String taskId) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _taskRepository.updateTaskStatus(
        taskId: taskId,
        status: TaskStatus.inProgress,
        startedAt: DateTime.now(),
      );
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Error starting task: $e');
      _setLoading(false);
      return false;
    }
  }

  // UPDATE - Submit task for review (staff action)
  Future<bool> submitTask({
    required String taskId,
    String? staffComments,
    List<String>? staffImages,
    bool? complianceStatus,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _taskRepository.submitTask(
        taskId: taskId,
        staffComments: staffComments,
        staffImages: staffImages,
        complianceStatus: complianceStatus,
      );
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Error submitting task: $e');
      _setLoading(false);
      return false;
    }
  }

  // UPDATE - Approve task (admin action)
  Future<bool> approveTask({
    required String taskId,
    String? adminComments,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _taskRepository.approveTask(
        taskId: taskId,
        adminComments: adminComments,
      );
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Error approving task: $e');
      _setLoading(false);
      return false;
    }
  }

  // UPDATE - Reject task (admin action)
  Future<bool> rejectTask({
    required String taskId,
    String? adminComments,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _taskRepository.rejectTask(
        taskId: taskId,
        adminComments: adminComments,
      );
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Error rejecting task: $e');
      _setLoading(false);
      return false;
    }
  }

  // UPDATE - Mark task as incomplete (admin action)
  Future<bool> markTaskIncomplete({
    required String taskId,
    String? adminComments,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _taskRepository.markTaskIncomplete(
        taskId: taskId,
        adminComments: adminComments,
      );
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Error marking task incomplete: $e');
      _setLoading(false);
      return false;
    }
  }

  // DELETE - Delete task
  Future<bool> deleteTask(String taskId) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _taskRepository.deleteTask(taskId);
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Error deleting task: $e');
      _setLoading(false);
      return false;
    }
  }

  // FILTERS - Update filters
  void setClientFilter(String? clientId) {
    _selectedClientId = clientId;
    notifyListeners();
  }

  void setAssigneeFilter(String? assignee) {
    _selectedAssignee = assignee;
    notifyListeners();
  }

  void setStatusFilter(TaskStatus? status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setSourceFilter(TaskSource? source) {
    _selectedSource = source;
    notifyListeners();
  }

  void setPriorityFilter(TaskPriority? priority) {
    _selectedPriority = priority;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _selectedClientId = null;
    _selectedAssignee = null;
    _selectedStatus = null;
    _selectedSource = null;
    _selectedPriority = null;
    _searchQuery = '';
    notifyListeners();
  }

  // REPETITIVE TASKS - Generate daily instances
  Future<void> generateDailyRepetitiveTasks() async {
    try {
      final templates = await _taskRepository.getRepetitiveTasks();

      for (final template in templates) {
        // Check if today's instance already exists
        final existingTasks = _tasks.where((task) {
          return task.title == template.title &&
              task.clientId == template.clientId &&
              task.assignedTo.toString() == template.assignedTo.toString() &&
              _isSameDay(task.assignedDate, DateTime.now());
        }).toList();

        // If no instance for today, create one
        if (existingTasks.isEmpty) {
          final today = DateTime.now();
          final dailyTask = template.copyWith(
            id: '', // New ID will be generated
            assignedDate: DateTime(
              today.year,
              today.month,
              today.day,
              template.assignedDate.hour,
              template.assignedDate.minute,
            ),
            dueDate: DateTime(
              today.year,
              today.month,
              today.day,
              template.dueDate.hour,
              template.dueDate.minute,
            ),
            type: TaskType.oneTime, // Daily instance is one-time
            createdAt: DateTime.now(),
            status: TaskStatus.assigned,
          );

          await createTask(dailyTask);
        }
      }
    } catch (e) {
      debugPrint('Error generating daily repetitive tasks: $e');
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Refresh tasks
  Future<void> refreshTasks() async {
    _setLoading(true);
    try {
      final tasks = await _taskRepository.getAllTasks();
      _tasks = tasks;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Error refreshing tasks: $e');
      _setLoading(false);
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

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }
}
