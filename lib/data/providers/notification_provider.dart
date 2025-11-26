import 'dart:async';
import 'package:flutter/material.dart';
import 'package:surakshith/data/models/notification_model.dart';
import 'package:surakshith/data/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _notificationRepository = NotificationRepository();

  bool _isLoading = false;
  String _errorMessage = '';
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  StreamSubscription<List<NotificationModel>>? _notificationsSubscription;
  StreamSubscription<int>? _unreadCountSubscription;

  String? _currentUserId;

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get hasUnread => _unreadCount > 0;

  // Get unread notifications only
  List<NotificationModel> get unreadNotifications {
    return _notifications.where((n) => n.isUnread).toList();
  }

  // Get read notifications only
  List<NotificationModel> get readNotifications {
    return _notifications.where((n) => n.isRead).toList();
  }

  // Get recent notifications (last 24 hours)
  List<NotificationModel> get recentNotifications {
    return _notifications.where((n) => n.isRecent).toList();
  }

  // Get today's notifications
  List<NotificationModel> get todayNotifications {
    return _notifications.where((n) => n.isToday).toList();
  }

  // Get notifications by type
  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  // Get task-related notifications
  List<NotificationModel> get taskNotifications {
    return _notifications.where((n) => n.isTaskRelated).toList();
  }

  // Get report-related notifications
  List<NotificationModel> get reportNotifications {
    return _notifications.where((n) => n.isReportRelated).toList();
  }

  // Initialize and listen to real-time updates for a user
  Future<void> init(String userId) async {
    _currentUserId = userId;
    _setLoading(true);

    try {
      await _notificationRepository.init();

      // Listen to real-time notification updates
      _notificationsSubscription = _notificationRepository
          .getNotificationsByUserStream(userId)
          .listen(
        (notifications) {
          _notifications = notifications;
          _setLoading(false);
          notifyListeners();
        },
        onError: (error) {
          _setError('Error listening to notifications: $error');
          _setLoading(false);
        },
      );

      // Listen to unread count
      _unreadCountSubscription =
          _notificationRepository.getUnreadCountStream(userId).listen(
        (count) {
          _unreadCount = count;
          notifyListeners();
        },
        onError: (error) {
          print('Error listening to unread count: $error');
        },
      );
    } catch (e) {
      _setError('Error initializing notification provider: $e');
      _setLoading(false);
    }
  }

  // CREATE - Create notification
  Future<String?> createNotification(NotificationModel notification) async {
    try {
      final notificationId =
          await _notificationRepository.createNotification(notification);
      return notificationId;
    } catch (e) {
      _setError('Error creating notification: $e');
      return null;
    }
  }

  // CREATE - Batch create notifications
  Future<List<String>> createNotificationBatch(
      List<NotificationModel> notifications) async {
    try {
      final notificationIds =
          await _notificationRepository.createNotificationBatch(notifications);
      return notificationIds;
    } catch (e) {
      _setError('Error creating notification batch: $e');
      return [];
    }
  }

  // CREATE - Helper methods for common notification types

  // Notify when task is assigned
  Future<void> notifyTaskAssigned({
    required String taskId,
    required String taskTitle,
    required List<String> assignedToUserIds,
    required String assignedBy,
  }) async {
    final notifications = assignedToUserIds.map((userId) {
      return NotificationModel.taskAssigned(
        id: '', // Will be generated
        userId: userId,
        taskId: taskId,
        taskTitle: taskTitle,
        assignedBy: assignedBy,
      );
    }).toList();

    await createNotificationBatch(notifications);
  }

  // Notify when task is completed
  Future<void> notifyTaskCompleted({
    required String taskId,
    required String taskTitle,
    required String completedBy,
    required List<String> notifyUserIds, // Usually the admin/auditor
  }) async {
    final notifications = notifyUserIds.map((userId) {
      return NotificationModel.taskCompleted(
        id: '', // Will be generated
        userId: userId,
        taskId: taskId,
        taskTitle: taskTitle,
        completedBy: completedBy,
      );
    }).toList();

    await createNotificationBatch(notifications);
  }

  // Notify when task is approved
  Future<void> notifyTaskApproved({
    required String taskId,
    required String taskTitle,
    required String approvedBy,
    required List<String> notifyUserIds, // The staff who completed it
  }) async {
    final notifications = notifyUserIds.map((userId) {
      return NotificationModel.taskApproved(
        id: '', // Will be generated
        userId: userId,
        taskId: taskId,
        taskTitle: taskTitle,
        approvedBy: approvedBy,
      );
    }).toList();

    await createNotificationBatch(notifications);
  }

  // Notify when task is rejected
  Future<void> notifyTaskRejected({
    required String taskId,
    required String taskTitle,
    required String rejectedBy,
    required List<String> notifyUserIds, // The staff who need to redo it
    String? reason,
  }) async {
    final notifications = notifyUserIds.map((userId) {
      return NotificationModel.taskRejected(
        id: '', // Will be generated
        userId: userId,
        taskId: taskId,
        taskTitle: taskTitle,
        rejectedBy: rejectedBy,
        reason: reason,
      );
    }).toList();

    await createNotificationBatch(notifications);
  }

  // Notify when audit report is created
  Future<void> notifyReportCreated({
    required String reportId,
    required String clientName,
    required String createdBy,
    required List<String> notifyUserIds, // Client users
  }) async {
    final notifications = notifyUserIds.map((userId) {
      return NotificationModel.reportCreated(
        id: '', // Will be generated
        userId: userId,
        reportId: reportId,
        clientName: clientName,
        createdBy: createdBy,
      );
    }).toList();

    await createNotificationBatch(notifications);
  }

  // UPDATE - Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      final success = await _notificationRepository.markAsRead(notificationId);
      return success;
    } catch (e) {
      _setError('Error marking notification as read: $e');
      return false;
    }
  }

  // UPDATE - Mark multiple notifications as read
  Future<bool> markMultipleAsRead(List<String> notificationIds) async {
    try {
      final success =
          await _notificationRepository.markMultipleAsRead(notificationIds);
      return success;
    } catch (e) {
      _setError('Error marking multiple notifications as read: $e');
      return false;
    }
  }

  // UPDATE - Mark all notifications as read
  Future<bool> markAllAsRead() async {
    if (_currentUserId == null) {
      _setError('No user logged in');
      return false;
    }

    try {
      final success =
          await _notificationRepository.markAllAsRead(_currentUserId!);
      return success;
    } catch (e) {
      _setError('Error marking all notifications as read: $e');
      return false;
    }
  }

  // DELETE - Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final success =
          await _notificationRepository.deleteNotification(notificationId);
      return success;
    } catch (e) {
      _setError('Error deleting notification: $e');
      return false;
    }
  }

  // DELETE - Delete multiple notifications
  Future<bool> deleteMultipleNotifications(List<String> notificationIds) async {
    try {
      final success = await _notificationRepository
          .deleteMultipleNotifications(notificationIds);
      return success;
    } catch (e) {
      _setError('Error deleting multiple notifications: $e');
      return false;
    }
  }

  // DELETE - Delete all notifications
  Future<bool> deleteAllNotifications() async {
    if (_currentUserId == null) {
      _setError('No user logged in');
      return false;
    }

    try {
      final success =
          await _notificationRepository.deleteAllNotifications(_currentUserId!);
      return success;
    } catch (e) {
      _setError('Error deleting all notifications: $e');
      return false;
    }
  }

  // DELETE - Clean up old notifications (older than 30 days)
  Future<int> cleanupOldNotifications() async {
    if (_currentUserId == null) {
      _setError('No user logged in');
      return 0;
    }

    try {
      final deletedCount =
          await _notificationRepository.cleanupOldNotifications(_currentUserId!);
      return deletedCount;
    } catch (e) {
      _setError('Error cleaning up old notifications: $e');
      return 0;
    }
  }

  // Refresh notifications
  Future<void> refreshNotifications() async {
    if (_currentUserId == null) {
      _setError('No user logged in');
      return;
    }

    _setLoading(true);
    try {
      final notifications = await _notificationRepository
          .getNotificationsByUser(_currentUserId!);
      _notifications = notifications;

      final count =
          await _notificationRepository.getUnreadCount(_currentUserId!);
      _unreadCount = count;

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Error refreshing notifications: $e');
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
    _notificationsSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    super.dispose();
  }
}
