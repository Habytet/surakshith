import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surakshith/data/models/audit_area_entry_model.dart';

class AuditAreaEntryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize repository (no longer needed, but keeping for API compatibility)
  Future<void> init() async {
    // Firestore doesn't need initialization
    // Offline persistence is enabled globally in main.dart
  }

  // Get entries collection for a specific report
  CollectionReference _getEntriesCollection(
      String clientId, String projectId, String reportId) {
    return _firestore
        .collection('clients')
        .doc(clientId)
        .collection('projects')
        .doc(projectId)
        .collection('reports')
        .doc(reportId)
        .collection('auditEntries');
  }

  // Get all entries across all reports as a Stream (real-time updates!)
  // Uses collectionGroup to query all 'auditEntries' subcollections
  Stream<List<AuditAreaEntryModel>> getAllEntriesStream() {
    return _firestore.collectionGroup('auditEntries').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data();
                // Ensure reportId is set from the document path
                // Path format: clients/{clientId}/projects/{projectId}/reports/{reportId}/auditEntries/{entryId}
                final pathSegments = doc.reference.path.split('/');
                if (pathSegments.length >= 6) {
                  data['reportId'] = pathSegments[5];
                }
                return AuditAreaEntryModel.fromMap(data);
              })
              .toList(),
        );
  }

  // Get entries for a specific report as a Stream (real-time updates!)
  Stream<List<AuditAreaEntryModel>> getEntriesByReportStream(
      String clientId, String projectId, String reportId) {
    return _getEntriesCollection(clientId, projectId, reportId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['reportId'] = reportId; // Ensure reportId is set
                return AuditAreaEntryModel.fromMap(data);
              })
              .toList(),
        );
  }

  // Get all entries (one-time fetch for compatibility)
  Future<List<AuditAreaEntryModel>> getAllEntries() async {
    try {
      final snapshot = await _firestore.collectionGroup('auditEntries').get();
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            // Extract reportId from document path
            final pathSegments = doc.reference.path.split('/');
            if (pathSegments.length >= 6) {
              data['reportId'] = pathSegments[5];
            }
            return AuditAreaEntryModel.fromMap(data);
          })
          .toList();
    } catch (e) {
      // If offline, Firestore will return cached data automatically
      rethrow;
    }
  }

  // Get entries by report (one-time fetch for compatibility)
  Future<List<AuditAreaEntryModel>> getEntriesByReport(
      String clientId, String projectId, String reportId) async {
    try {
      final snapshot =
          await _getEntriesCollection(clientId, projectId, reportId).get();
      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['reportId'] = reportId;
            return AuditAreaEntryModel.fromMap(data);
          })
          .toList();
    } catch (e) {
      // If offline, Firestore will return cached data automatically
      rethrow;
    }
  }

  // Add entry (stores in Firestore subcollection)
  // Firestore offline persistence handles local caching automatically
  Future<String> addEntry({
    required String clientId,
    required String projectId,
    required String reportId,
    required String auditAreaId,
    required String responsiblePersonId,
    required List<String> auditIssueIds,
    required String risk,
    required String observation,
    required String recommendation,
    DateTime? deadlineDate,
    List<String>? imageUrls,
  }) async {
    // Generate unique ID
    final docRef =
        _getEntriesCollection(clientId, projectId, reportId).doc();
    final entryId = docRef.id;

    final entry = AuditAreaEntryModel(
      id: entryId,
      reportId: reportId,
      auditAreaId: auditAreaId,
      responsiblePersonId: responsiblePersonId,
      auditIssueIds: auditIssueIds,
      risk: risk,
      observation: observation,
      recommendation: recommendation,
      deadlineDate: deadlineDate,
      imageUrls: imageUrls ?? [],
      createdAt: DateTime.now(),
    );

    // Write to Firestore subcollection
    // If offline, this will be cached locally and synced automatically when online
    await docRef.set(entry.toMap());

    return entryId;
  }

  // Update entry (updates in Firestore subcollection)
  // Firestore offline persistence handles local caching automatically
  Future<void> updateEntry({
    required String clientId,
    required String projectId,
    required String reportId,
    required String id,
    String? auditAreaId,
    String? responsiblePersonId,
    List<String>? auditIssueIds,
    String? risk,
    String? observation,
    String? recommendation,
    DateTime? deadlineDate,
    List<String>? imageUrls,
  }) async {
    final updateData = <String, dynamic>{};
    if (auditAreaId != null) updateData['auditAreaId'] = auditAreaId;
    if (responsiblePersonId != null) {
      updateData['responsiblePersonId'] = responsiblePersonId;
    }
    if (auditIssueIds != null) updateData['auditIssueIds'] = auditIssueIds;
    if (risk != null) updateData['risk'] = risk;
    if (observation != null) updateData['observation'] = observation;
    if (recommendation != null) updateData['recommendation'] = recommendation;
    if (deadlineDate != null) {
      updateData['deadlineDate'] = deadlineDate.millisecondsSinceEpoch;
    }
    if (imageUrls != null) updateData['imageUrls'] = imageUrls;

    // Update in Firestore subcollection
    // If offline, this will be cached locally and synced automatically when online
    await _getEntriesCollection(clientId, projectId, reportId)
        .doc(id)
        .update(updateData);
  }

  // Delete entry (deletes from Firestore subcollection)
  // Firestore offline persistence handles local caching automatically
  Future<void> deleteEntry({
    required String clientId,
    required String projectId,
    required String reportId,
    required String id,
  }) async {
    // Delete from Firestore subcollection
    // If offline, this will be cached locally and synced automatically when online
    await _getEntriesCollection(clientId, projectId, reportId)
        .doc(id)
        .delete();
  }

  // No longer need manual sync methods!
  // Firestore handles all syncing automatically with offline persistence
}
