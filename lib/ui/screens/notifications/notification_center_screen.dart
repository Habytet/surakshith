import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:surakshith/data/models/notification_model.dart';
import 'package:surakshith/data/providers/notification_provider.dart';
import 'package:surakshith/ui/screens/tasks/task_detail_screen.dart';
import 'package:intl/intl.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  String _formatNotificationTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.taskAssigned:
        return Icons.assignment_outlined;
      case NotificationType.taskUpdated:
        return Icons.update;
      case NotificationType.taskCompleted:
        return Icons.check_circle_outline;
      case NotificationType.taskRejected:
        return Icons.cancel_outlined;
      case NotificationType.taskApproved:
        return Icons.verified_outlined;
      case NotificationType.taskOverdue:
        return Icons.warning_amber_outlined;
      case NotificationType.reportCreated:
        return Icons.description_outlined;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.taskAssigned:
        return const Color(0xFF2196F3);
      case NotificationType.taskUpdated:
        return const Color(0xFFFF9800);
      case NotificationType.taskCompleted:
        return const Color(0xFF4CAF50);
      case NotificationType.taskRejected:
        return const Color(0xFFF44336);
      case NotificationType.taskApproved:
        return const Color(0xFF4CAF50);
      case NotificationType.taskOverdue:
        return const Color(0xFFF44336);
      case NotificationType.reportCreated:
        return const Color(0xFF9C27B0);
    }
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    NotificationModel notification,
    NotificationProvider provider,
  ) async {
    // Mark as read
    if (notification.isUnread) {
      await provider.markAsRead(notification.id);
    }

    // Navigate to related screen
    if (notification.taskId != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskDetailScreen(taskId: notification.taskId!),
        ),
      );
    }
    // Add navigation for report if needed
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: const Color(0xFFE91E63),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please log in to view notifications'),
        ),
      );
    }

    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F7F7),
          appBar: AppBar(
            title: const Text('Notifications'),
            backgroundColor: const Color(0xFFE91E63),
            foregroundColor: Colors.white,
            actions: [
              StreamBuilder<int>(
                stream: notificationProvider.getUnreadCountStream(currentUser.email!),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  if (unreadCount > 0) {
                    return TextButton(
                      onPressed: () async {
                        await notificationProvider.markAllAsRead();
                      },
                      child: const Text(
                        'Mark all read',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: StreamBuilder<List<NotificationModel>>(
            stream: notificationProvider.getNotificationsByUserStream(currentUser.email!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading notifications',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              final notifications = snapshot.data ?? [];

              if (notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You\'re all caught up!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Group notifications by date
              final today = <NotificationModel>[];
              final yesterday = <NotificationModel>[];
              final older = <NotificationModel>[];

              final now = DateTime.now();
              final todayStart = DateTime(now.year, now.month, now.day);
              final yesterdayStart = todayStart.subtract(const Duration(days: 1));

              for (final notification in notifications) {
                if (notification.createdAt.isAfter(todayStart)) {
                  today.add(notification);
                } else if (notification.createdAt.isAfter(yesterdayStart)) {
                  yesterday.add(notification);
                } else {
                  older.add(notification);
                }
              }

              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  if (today.isNotEmpty) ...[
                    _buildSectionHeader('Today'),
                    ...today.map((n) => _buildNotificationTile(context, n, notificationProvider)),
                  ],
                  if (yesterday.isNotEmpty) ...[
                    _buildSectionHeader('Yesterday'),
                    ...yesterday.map((n) => _buildNotificationTile(context, n, notificationProvider)),
                  ],
                  if (older.isNotEmpty) ...[
                    _buildSectionHeader('Earlier'),
                    ...older.map((n) => _buildNotificationTile(context, n, notificationProvider)),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: Platform.isIOS ? 13 : 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    NotificationModel notification,
    NotificationProvider provider,
  ) {
    final icon = _getNotificationIcon(notification.type);
    final color = _getNotificationColor(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        provider.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead ? Colors.grey[200]! : color.withValues(alpha: 0.2),
            width: notification.isRead ? 1 : 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleNotificationTap(context, notification, provider),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: Platform.isIOS ? 14 : 15,
                                  fontWeight: notification.isUnread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: const Color(0xFF222222),
                                ),
                              ),
                            ),
                            if (notification.isUnread)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: TextStyle(
                            fontSize: Platform.isIOS ? 13 : 14,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatNotificationTime(notification.createdAt),
                          style: TextStyle(
                            fontSize: Platform.isIOS ? 11 : 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
