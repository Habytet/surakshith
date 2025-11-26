import 'package:flutter/foundation.dart';

// Simplified BackgroundSyncService for Firestore migration
// Firestore handles all syncing automatically with offline persistence
// This service now just provides a minimal API for backward compatibility
class BackgroundSyncService extends ChangeNotifier {
  static final BackgroundSyncService _instance = BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();

  bool _isSyncing = false;
  int _totalPending = 0;
  int _totalCompleted = 0;

  bool get isSyncing => _isSyncing;
  int get totalPending => _totalPending;
  int get totalCompleted => _totalCompleted;
  int get queueLength => 0; // Always 0 since Firestore handles syncing automatically

  // Dummy methods for backward compatibility
  // Firestore handles all syncing automatically
  void addToQueue(String entryId) {
    // No-op: Firestore handles syncing automatically
  }

  void removeFromQueue(String entryId) {
    // No-op: Firestore handles syncing automatically
  }

  Future<void> syncAll() async {
    // No-op: Firestore handles syncing automatically
  }

  Future<void> syncEntry(String entryId) async {
    // No-op: Firestore handles syncing automatically
  }

  Future<bool> isFullySynced() async {
    // Always return true since Firestore handles syncing automatically
    return true;
  }
}
