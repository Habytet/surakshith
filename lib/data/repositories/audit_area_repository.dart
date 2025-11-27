import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surakshith/data/models/audit_area_model.dart';

class AuditAreaRepository {
  final CollectionReference _auditAreasCollection =
      FirebaseFirestore.instance.collection('audit_areas');

  // Initialize repository (no longer needed, but keeping for API compatibility)
  Future<void> init() async {
    // Firestore doesn't need initialization
    // Offline persistence is enabled globally in main.dart
  }

  // Get all audit areas as a Stream (real-time updates!)
  Stream<List<AuditAreaModel>> getAuditAreasStream() {
    return _auditAreasCollection.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => AuditAreaModel.fromMap(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  // Get all audit areas (one-time fetch for compatibility)
  Future<List<AuditAreaModel>> getAllAuditAreas() async {
    try {
      final snapshot = await _auditAreasCollection.get();
      return snapshot.docs
          .map((doc) => AuditAreaModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If offline, Firestore will return cached data automatically
      rethrow;
    }
  }

  // Add audit area (stores in Firestore)
  // Firestore offline persistence handles local caching automatically
  Future<void> addAuditArea({required String name}) async {
    // Generate unique ID
    final docRef = _auditAreasCollection.doc();
    final auditAreaId = docRef.id;

    final auditArea = AuditAreaModel(
      id: auditAreaId,
      name: name,
      createdAt: DateTime.now(),
    );

    // Write to Firestore
    // If offline, this will be cached locally and synced automatically when online
    await docRef.set(auditArea.toMap());
  }

  // Update audit area (updates in Firestore)
  // Firestore offline persistence handles local caching automatically
  Future<void> updateAuditArea({
    required String id,
    required String name,
  }) async {
    // Update in Firestore
    // If offline, this will be cached locally and synced automatically when online
    await _auditAreasCollection.doc(id).update({
      'name': name,
    });
  }

  // Delete audit area (deletes from Firestore)
  // Firestore offline persistence handles local caching automatically
  Future<void> deleteAuditArea({required String id}) async {
    // Delete from Firestore
    // If offline, this will be cached locally and synced automatically when online
    await _auditAreasCollection.doc(id).delete();
  }

  // No longer need manual sync methods!
  // Firestore handles all syncing automatically with offline persistence
}
