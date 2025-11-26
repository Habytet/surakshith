import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surakshith/data/models/report_model.dart';

class ReportRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize repository (no longer needed, but keeping for API compatibility)
  Future<void> init() async {
    // Firestore doesn't need initialization
    // Offline persistence is enabled globally in main.dart
  }

  // Get reports collection for a specific project
  CollectionReference _getReportsCollection(String clientId, String projectId) {
    return _firestore
        .collection('clients')
        .doc(clientId)
        .collection('projects')
        .doc(projectId)
        .collection('reports');
  }

  // Get all reports across all projects as a Stream (real-time updates!)
  // Uses collectionGroup to query all 'reports' subcollections
  Stream<List<ReportModel>> getAllReportsStream() {
    return _firestore.collectionGroup('reports').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data();
                // Ensure clientId and projectId are set from the document path
                // Path format: clients/{clientId}/projects/{projectId}/reports/{reportId}
                final pathSegments = doc.reference.path.split('/');
                if (pathSegments.length >= 4) {
                  data['clientId'] = pathSegments[1];
                  data['projectId'] = pathSegments[3];
                }
                return ReportModel.fromMap(data);
              })
              .toList(),
        );
  }

  // Get reports for a specific project as a Stream (real-time updates!)
  Stream<List<ReportModel>> getReportsByProjectStream(String clientId, String projectId) {
    return _getReportsCollection(clientId, projectId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['clientId'] = clientId; // Ensure clientId is set
                data['projectId'] = projectId; // Ensure projectId is set
                return ReportModel.fromMap(data);
              })
              .toList(),
        );
  }

  // Get all reports (one-time fetch for compatibility)
  Future<List<ReportModel>> getAllReports() async {
    try {
      final snapshot = await _firestore.collectionGroup('reports').get();
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            // Extract clientId and projectId from document path
            final pathSegments = doc.reference.path.split('/');
            if (pathSegments.length >= 4) {
              data['clientId'] = pathSegments[1];
              data['projectId'] = pathSegments[3];
            }
            return ReportModel.fromMap(data);
          })
          .toList();
    } catch (e) {
      // If offline, Firestore will return cached data automatically
      rethrow;
    }
  }

  // Get reports by project (one-time fetch for compatibility)
  Future<List<ReportModel>> getReportsByProject(String clientId, String projectId) async {
    try {
      final snapshot = await _getReportsCollection(clientId, projectId).get();
      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['clientId'] = clientId;
            data['projectId'] = projectId;
            return ReportModel.fromMap(data);
          })
          .toList();
    } catch (e) {
      // If offline, Firestore will return cached data automatically
      rethrow;
    }
  }

  // Add report (stores in Firestore subcollection)
  // Firestore offline persistence handles local caching automatically
  Future<String> addReport({
    required String clientId,
    required String projectId,
    required DateTime reportDate,
    String status = 'draft',
    String? contactName,
  }) async {
    // Generate unique ID
    final docRef = _getReportsCollection(clientId, projectId).doc();
    final reportId = docRef.id;

    final report = ReportModel(
      id: reportId,
      clientId: clientId,
      projectId: projectId,
      reportDate: reportDate,
      createdAt: DateTime.now(),
      status: status,
      contactName: contactName,
    );

    // Write to Firestore subcollection
    // If offline, this will be cached locally and synced automatically when online
    await docRef.set(report.toMap());

    return reportId;
  }

  // Update report (updates in Firestore subcollection)
  // Firestore offline persistence handles local caching automatically
  Future<void> updateReport({
    required String clientId,
    required String projectId,
    required String id,
    DateTime? reportDate,
    String? status,
    List<String>? imageUrls,
    String? contactName,
  }) async {
    final updateData = <String, dynamic>{};
    if (reportDate != null) {
      updateData['reportDate'] = reportDate.millisecondsSinceEpoch;
    }
    if (status != null) {
      updateData['status'] = status;
    }
    if (imageUrls != null) {
      updateData['imageUrls'] = imageUrls;
    }
    if (contactName != null) {
      updateData['contactName'] = contactName;
    }

    // Update in Firestore subcollection
    // If offline, this will be cached locally and synced automatically when online
    await _getReportsCollection(clientId, projectId)
        .doc(id)
        .update(updateData);
  }

  // Delete report (deletes from Firestore subcollection)
  // Firestore offline persistence handles local caching automatically
  Future<void> deleteReport({
    required String clientId,
    required String projectId,
    required String id,
  }) async {
    // Delete from Firestore subcollection
    // If offline, this will be cached locally and synced automatically when online
    await _getReportsCollection(clientId, projectId).doc(id).delete();
  }

  // No longer need manual sync methods!
  // Firestore handles all syncing automatically with offline persistence
}
