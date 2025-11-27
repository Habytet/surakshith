import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surakshith/data/models/audit_issue_model.dart';

class AuditIssueRepository {
  final CollectionReference _auditIssuesCollection =
      FirebaseFirestore.instance.collection('audit_issues');

  // Initialize repository (no longer needed, but keeping for API compatibility)
  Future<void> init() async {
    // Firestore doesn't need initialization
    // Offline persistence is enabled globally in main.dart
  }

  // Get all audit issues as a Stream (real-time updates!)
  Stream<List<AuditIssueModel>> getAuditIssuesStream() {
    return _auditIssuesCollection.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => AuditIssueModel.fromMap(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  // Get all audit issues (one-time fetch for compatibility)
  Future<List<AuditIssueModel>> getAllAuditIssues() async {
    try {
      final snapshot = await _auditIssuesCollection.get();
      return snapshot.docs
          .map((doc) => AuditIssueModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If offline, Firestore will return cached data automatically
      rethrow;
    }
  }

  // Add audit issue (stores in Firestore)
  // Firestore offline persistence handles local caching automatically
  Future<void> addAuditIssue({
    required String name,
    List<int>? clauseNumbers,
  }) async {
    // Generate unique ID
    final docRef = _auditIssuesCollection.doc();
    final auditIssueId = docRef.id;

    final auditIssue = AuditIssueModel(
      id: auditIssueId,
      name: name,
      createdAt: DateTime.now(),
      clauseNumbers: clauseNumbers ?? [],
    );

    // Write to Firestore
    // If offline, this will be cached locally and synced automatically when online
    await docRef.set(auditIssue.toMap());
  }

  // Update audit issue (updates in Firestore)
  // Firestore offline persistence handles local caching automatically
  Future<void> updateAuditIssue({
    required String id,
    required String name,
    List<int>? clauseNumbers,
  }) async {
    // Update in Firestore
    // If offline, this will be cached locally and synced automatically when online
    await _auditIssuesCollection.doc(id).update({
      'name': name,
      'clauseNumbers': clauseNumbers ?? [],
    });
  }

  // Delete audit issue (deletes from Firestore)
  // Firestore offline persistence handles local caching automatically
  Future<void> deleteAuditIssue({required String id}) async {
    // Delete from Firestore
    // If offline, this will be cached locally and synced automatically when online
    await _auditIssuesCollection.doc(id).delete();
  }

  // No longer need manual sync methods!
  // Firestore handles all syncing automatically with offline persistence
}
