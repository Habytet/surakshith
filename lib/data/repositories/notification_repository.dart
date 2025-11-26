import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surakshith/data/models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get notifications collection reference
  CollectionReference get _notificationsCollection =>
      _firestore.collection('notifications');

  // Initialize repository
  Future<void> init() async {
    // Firestore doesn't need initialization
    // Offline persistence is enabled globally in main.dart
  }

  // CREATE - Add a new notification
  Future<String?> createNotification(NotificationModel notification) async {
    try {
      final docRef = await _notificationsCollection.add(notification.toMap());

      // Update the notification with the generated ID
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      print('Error creating notification: $e');
      rethrow;
    }
  }

  // CREATE - Batch create notifications (for multiple users)
  Future<List<String>> createNotificationBatch(
      List<NotificationModel> notifications) async {
    try {
      final batch = _firestore.batch();
      final List<String> notificationIds = [];

      for (final notification in notifications) {
        final docRef = _notificationsCollection.doc();
        notificationIds.add(docRef.id);

        final notificationWithId = notification.copyWith(id: docRef.id);
        batch.set(docRef, notificationWithId.toMap());
      }

      await batch.commit();
      return notificationIds;
    } catch (e) {
      print('Error creating notification batch: $e');
      rethrow;
    }
  }

  // READ - Get notification by ID (one-time)
  Future<NotificationModel?> getNotificationById(String notificationId) async {
    try {
      final doc = await _notificationsCollection.doc(notificationId).get();

      if (doc.exists && doc.data() != null) {
        return NotificationModel.fromMap(doc.data() as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      print('Error getting notification by ID: $e');
      rethrow;
    }
  }

  // READ - Get notifications for a user (one-time)
  Future<List<NotificationModel>> getNotificationsByUser(String userId) async {
    try {
      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              NotificationModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting notifications by user: $e');
      rethrow;
    }
  }

  // READ - Stream notifications for a user (real-time)
  Stream<List<NotificationModel>> getNotificationsByUserStream(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                NotificationModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // READ - Get unread notifications for a user (one-time)
  Future<List<NotificationModel>> getUnreadNotifications(String userId) async {
    try {
      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              NotificationModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting unread notifications: $e');
      rethrow;
    }
  }

  // READ - Stream unread notifications for a user (real-time)
  Stream<List<NotificationModel>> getUnreadNotificationsStream(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                NotificationModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // READ - Get unread count for a user
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting unread count: $e');
      rethrow;
    }
  }

  // READ - Stream unread count (real-time)
  Stream<int> getUnreadCountStream(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // READ - Get notifications by task
  Future<List<NotificationModel>> getNotificationsByTask(String taskId) async {
    try {
      final snapshot = await _notificationsCollection
          .where('taskId', isEqualTo: taskId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              NotificationModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting notifications by task: $e');
      rethrow;
    }
  }

  // READ - Get notifications by type
  Future<List<NotificationModel>> getNotificationsByType({
    required String userId,
    required NotificationType type,
  }) async {
    try {
      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: type.toJson())
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              NotificationModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting notifications by type: $e');
      rethrow;
    }
  }

  // READ - Get recent notifications (last 24 hours)
  Future<List<NotificationModel>> getRecentNotifications(String userId) async {
    try {
      final yesterday =
          DateTime.now().subtract(const Duration(hours: 24)).millisecondsSinceEpoch;

      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThan: yesterday)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              NotificationModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting recent notifications: $e');
      rethrow;
    }
  }

  // UPDATE - Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
      });
      return true;
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  // UPDATE - Mark multiple notifications as read
  Future<bool> markMultipleAsRead(List<String> notificationIds) async {
    try {
      final batch = _firestore.batch();

      for (final notificationId in notificationIds) {
        batch.update(
          _notificationsCollection.doc(notificationId),
          {'isRead': true},
        );
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error marking multiple notifications as read: $e');
      rethrow;
    }
  }

  // UPDATE - Mark all notifications as read for a user
  Future<bool> markAllAsRead(String userId) async {
    try {
      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  // DELETE - Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
      return true;
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  // DELETE - Delete multiple notifications
  Future<bool> deleteMultipleNotifications(List<String> notificationIds) async {
    try {
      final batch = _firestore.batch();

      for (final notificationId in notificationIds) {
        batch.delete(_notificationsCollection.doc(notificationId));
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error deleting multiple notifications: $e');
      rethrow;
    }
  }

  // DELETE - Delete all notifications for a user
  Future<bool> deleteAllNotifications(String userId) async {
    try {
      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error deleting all notifications: $e');
      rethrow;
    }
  }

  // DELETE - Clean up old notifications (older than 30 days)
  Future<int> cleanupOldNotifications(String userId) async {
    try {
      final thirtyDaysAgo =
          DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch;

      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('createdAt', isLessThan: thirtyDaysAgo)
          .get();

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return snapshot.docs.length;
    } catch (e) {
      print('Error cleaning up old notifications: $e');
      rethrow;
    }
  }
}
