import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surakshith/data/models/task_model.dart';

class TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get tasks collection reference
  CollectionReference get _tasksCollection => _firestore.collection('tasks');

  // Initialize repository
  Future<void> init() async {
    // Firestore doesn't need initialization
    // Offline persistence is enabled globally in main.dart
  }

  // CREATE - Add a new task
  Future<String?> createTask(TaskModel task) async {
    try {
      final docRef = await _tasksCollection.add(task.toMap());

      // Update the task with the generated ID
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      print('Error creating task: $e');
      rethrow;
    }
  }

  // CREATE - Batch create multiple tasks (for multi-user assignment)
  Future<List<String>> createTaskBatch(List<TaskModel> tasks) async {
    try {
      final batch = _firestore.batch();
      final List<String> taskIds = [];

      for (final task in tasks) {
        final docRef = _tasksCollection.doc();
        taskIds.add(docRef.id);

        final taskWithId = task.copyWith(id: docRef.id);
        batch.set(docRef, taskWithId.toMap());
      }

      await batch.commit();
      return taskIds;
    } catch (e) {
      print('Error creating task batch: $e');
      rethrow;
    }
  }

  // READ - Get task by ID (one-time)
  Future<TaskModel?> getTaskById(String taskId) async {
    try {
      final doc = await _tasksCollection.doc(taskId).get();

      if (doc.exists && doc.data() != null) {
        return TaskModel.fromMap(doc.data() as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      print('Error getting task by ID: $e');
      rethrow;
    }
  }

  // READ - Get all tasks (one-time)
  Future<List<TaskModel>> getAllTasks() async {
    try {
      final snapshot = await _tasksCollection.get();

      return snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting all tasks: $e');
      rethrow;
    }
  }

  // READ - Stream all tasks (real-time)
  Stream<List<TaskModel>> getAllTasksStream() {
    return _tasksCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // READ - Get tasks by client (one-time)
  Future<List<TaskModel>> getTasksByClient(String clientId) async {
    try {
      final snapshot = await _tasksCollection
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting tasks by client: $e');
      rethrow;
    }
  }

  // READ - Stream tasks by client (real-time)
  Stream<List<TaskModel>> getTasksByClientStream(String clientId) {
    return _tasksCollection
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // READ - Get tasks assigned to a user (one-time)
  Future<List<TaskModel>> getTasksByAssignee(String userEmail) async {
    try {
      final snapshot = await _tasksCollection
          .where('assignedTo', arrayContains: userEmail)
          .orderBy('dueDate', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting tasks by assignee: $e');
      rethrow;
    }
  }

  // READ - Stream tasks assigned to a user (real-time)
  Stream<List<TaskModel>> getTasksByAssigneeStream(String userEmail) {
    return _tasksCollection
        .where('assignedTo', arrayContains: userEmail)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // READ - Get tasks by status
  Future<List<TaskModel>> getTasksByStatus(TaskStatus status) async {
    try {
      final snapshot = await _tasksCollection
          .where('status', isEqualTo: status.toJson())
          .orderBy('dueDate', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting tasks by status: $e');
      rethrow;
    }
  }

  // READ - Stream tasks by status (real-time)
  Stream<List<TaskModel>> getTasksByStatusStream(TaskStatus status) {
    return _tasksCollection
        .where('status', isEqualTo: status.toJson())
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // READ - Get tasks by source (audit vs standalone)
  Future<List<TaskModel>> getTasksBySource(TaskSource source) async {
    try {
      final snapshot = await _tasksCollection
          .where('source', isEqualTo: source.toJson())
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting tasks by source: $e');
      rethrow;
    }
  }

  // READ - Stream tasks by source (real-time)
  Stream<List<TaskModel>> getTasksBySourceStream(TaskSource source) {
    return _tasksCollection
        .where('source', isEqualTo: source.toJson())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // READ - Get tasks linked to an audit report
  Future<List<TaskModel>> getTasksByAuditReport(String auditReportId) async {
    try {
      final snapshot = await _tasksCollection
          .where('auditReportId', isEqualTo: auditReportId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting tasks by audit report: $e');
      rethrow;
    }
  }

  // READ - Get repetitive task templates
  Future<List<TaskModel>> getRepetitiveTasks() async {
    try {
      final snapshot = await _tasksCollection
          .where('type', isEqualTo: TaskType.repetitive.toJson())
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting repetitive tasks: $e');
      rethrow;
    }
  }

  // READ - Stream repetitive task templates (real-time)
  Stream<List<TaskModel>> getRepetitiveTasksStream() {
    return _tasksCollection
        .where('type', isEqualTo: TaskType.repetitive.toJson())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // READ - Get overdue tasks
  Future<List<TaskModel>> getOverdueTasks() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      final snapshot = await _tasksCollection
          .where('dueDate', isLessThan: now)
          .where('status', whereIn: [
            TaskStatus.assigned.toJson(),
            TaskStatus.inProgress.toJson(),
            TaskStatus.pendingReview.toJson(),
          ])
          .orderBy('dueDate', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting overdue tasks: $e');
      rethrow;
    }
  }

  // UPDATE - Update task
  Future<bool> updateTask(TaskModel task) async {
    try {
      await _tasksCollection.doc(task.id).update(task.toMap());
      return true;
    } catch (e) {
      print('Error updating task: $e');
      rethrow;
    }
  }

  // UPDATE - Update task status only
  Future<bool> updateTaskStatus({
    required String taskId,
    required TaskStatus status,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? reviewedAt,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.toJson(),
      };

      if (startedAt != null) {
        updateData['startedAt'] = startedAt.millisecondsSinceEpoch;
      }
      if (completedAt != null) {
        updateData['completedAt'] = completedAt.millisecondsSinceEpoch;
      }
      if (reviewedAt != null) {
        updateData['reviewedAt'] = reviewedAt.millisecondsSinceEpoch;
      }

      await _tasksCollection.doc(taskId).update(updateData);
      return true;
    } catch (e) {
      print('Error updating task status: $e');
      rethrow;
    }
  }

  // UPDATE - Submit task (by staff)
  Future<bool> submitTask({
    required String taskId,
    String? staffComments,
    List<String>? staffImages,
    bool? complianceStatus,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': TaskStatus.pendingReview.toJson(),
        'completedAt': DateTime.now().millisecondsSinceEpoch,
      };

      if (staffComments != null) {
        updateData['staffComments'] = staffComments;
      }
      if (staffImages != null) {
        updateData['staffImages'] = staffImages;
      }
      if (complianceStatus != null) {
        updateData['complianceStatus'] = complianceStatus;
      }

      await _tasksCollection.doc(taskId).update(updateData);
      return true;
    } catch (e) {
      print('Error submitting task: $e');
      rethrow;
    }
  }

  // UPDATE - Approve task (by admin)
  Future<bool> approveTask({
    required String taskId,
    String? adminComments,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': TaskStatus.completed.toJson(),
        'isApproved': true,
        'reviewedAt': DateTime.now().millisecondsSinceEpoch,
      };

      if (adminComments != null && adminComments.trim().isNotEmpty) {
        updateData['adminComments'] = adminComments;
      }

      await _tasksCollection.doc(taskId).update(updateData);
      return true;
    } catch (e) {
      print('Error approving task: $e');
      rethrow;
    }
  }

  // UPDATE - Reject task (by admin)
  Future<bool> rejectTask({
    required String taskId,
    String? adminComments,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': TaskStatus.assigned.toJson(), // Send back to assigned
        'isApproved': false,
        'reviewedAt': DateTime.now().millisecondsSinceEpoch,
        // Clear staff response data for re-submission
        'staffComments': '',
        'staffImages': [],
        'complianceStatus': null,
        'startedAt': null,
        'completedAt': null,
      };

      if (adminComments != null && adminComments.trim().isNotEmpty) {
        updateData['adminComments'] = adminComments;
      }

      await _tasksCollection.doc(taskId).update(updateData);
      return true;
    } catch (e) {
      print('Error rejecting task: $e');
      rethrow;
    }
  }

  // UPDATE - Mark task as incomplete (by admin)
  Future<bool> markTaskIncomplete({
    required String taskId,
    String? adminComments,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': TaskStatus.incomplete.toJson(),
        'isApproved': false,
        'reviewedAt': DateTime.now().millisecondsSinceEpoch,
      };

      if (adminComments != null && adminComments.trim().isNotEmpty) {
        updateData['adminComments'] = adminComments;
      }

      await _tasksCollection.doc(taskId).update(updateData);
      return true;
    } catch (e) {
      print('Error marking task incomplete: $e');
      rethrow;
    }
  }

  // DELETE - Delete task
  Future<bool> deleteTask(String taskId) async {
    try {
      await _tasksCollection.doc(taskId).delete();
      return true;
    } catch (e) {
      print('Error deleting task: $e');
      rethrow;
    }
  }

  // DELETE - Batch delete tasks
  Future<bool> deleteTaskBatch(List<String> taskIds) async {
    try {
      final batch = _firestore.batch();

      for (final taskId in taskIds) {
        batch.delete(_tasksCollection.doc(taskId));
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error deleting task batch: $e');
      rethrow;
    }
  }

  // COMPLEX QUERIES - Get tasks with multiple filters
  Future<List<TaskModel>> getTasksWithFilters({
    String? clientId,
    String? assignedTo,
    TaskStatus? status,
    TaskSource? source,
    TaskPriority? priority,
    DateTime? dueDateBefore,
    DateTime? dueDateAfter,
  }) async {
    try {
      Query query = _tasksCollection;

      if (clientId != null) {
        query = query.where('clientId', isEqualTo: clientId);
      }
      if (assignedTo != null) {
        query = query.where('assignedTo', arrayContains: assignedTo);
      }
      if (status != null) {
        query = query.where('status', isEqualTo: status.toJson());
      }
      if (source != null) {
        query = query.where('source', isEqualTo: source.toJson());
      }
      if (priority != null) {
        query = query.where('priority', isEqualTo: priority.toJson());
      }
      if (dueDateBefore != null) {
        query = query.where('dueDate',
            isLessThan: dueDateBefore.millisecondsSinceEpoch);
      }
      if (dueDateAfter != null) {
        query = query.where('dueDate',
            isGreaterThan: dueDateAfter.millisecondsSinceEpoch);
      }

      query = query.orderBy('dueDate', descending: false);

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting tasks with filters: $e');
      rethrow;
    }
  }

  // STATISTICS - Get task counts by status
  Future<Map<TaskStatus, int>> getTaskCountsByStatus({String? clientId}) async {
    try {
      Query query = _tasksCollection;

      if (clientId != null) {
        query = query.where('clientId', isEqualTo: clientId);
      }

      final snapshot = await query.get();
      final tasks = snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      final Map<TaskStatus, int> counts = {
        TaskStatus.assigned: 0,
        TaskStatus.inProgress: 0,
        TaskStatus.pendingReview: 0,
        TaskStatus.completed: 0,
        TaskStatus.incomplete: 0,
      };

      for (final task in tasks) {
        counts[task.status] = (counts[task.status] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      print('Error getting task counts: $e');
      rethrow;
    }
  }
}
