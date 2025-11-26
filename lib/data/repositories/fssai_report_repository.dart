import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surakshith/data/models/fssai_report_model.dart';

class FssaiReportRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize repository (no longer needed, but keeping for API compatibility)
  Future<void> init() async {
    // Firestore doesn't need initialization
    // Offline persistence is enabled globally in main.dart
  }

  // Get FSSAI reports collection
  CollectionReference _getFssaiReportsCollection() {
    return _firestore.collection('fssaiReports');
  }

  // Get FSSAI report as a Stream (real-time updates!)
  Stream<FssaiReportModel?> getReportStream(String reportId) {
    return _getFssaiReportsCollection()
        .doc(reportId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return FssaiReportModel.fromMap(snapshot.data() as Map<String, dynamic>);
    });
  }

  // Get all FSSAI reports as a Stream
  Stream<List<FssaiReportModel>> getAllReportsStream() {
    return _getFssaiReportsCollection().snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => FssaiReportModel.fromMap(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  // Get FSSAI report (one-time fetch)
  Future<FssaiReportModel?> getReport(String reportId) async {
    try {
      final snapshot = await _getFssaiReportsCollection().doc(reportId).get();
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return FssaiReportModel.fromMap(snapshot.data() as Map<String, dynamic>);
    } catch (e) {
      // If offline, Firestore will return cached data automatically
      rethrow;
    }
  }

  // Save FSSAI report (creates or updates)
  Future<void> saveReport(FssaiReportModel report) async {
    await _getFssaiReportsCollection()
        .doc(report.reportId)
        .set(report.toMap());
  }

  // Delete FSSAI report
  Future<void> deleteReport(String reportId) async {
    await _getFssaiReportsCollection().doc(reportId).delete();
  }

  // Get all FSSAI reports (one-time fetch)
  Future<List<FssaiReportModel>> getAllReports() async {
    try {
      final snapshot = await _getFssaiReportsCollection().get();
      return snapshot.docs
          .map((doc) => FssaiReportModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If offline, Firestore will return cached data automatically
      rethrow;
    }
  }

  // Update score for a specific audit point
  Future<void> updateScore(String reportId, int serialNo, int score) async {
    final report = await getReport(reportId);
    if (report != null) {
      final updatedScores = Map<int, int>.from(report.scores);
      updatedScores[serialNo] = score;

      final updatedReport = report.copyWith(
        scores: updatedScores,
        lastModified: DateTime.now(),
      );

      await saveReport(updatedReport);
    }
  }

  // Update report details
  Future<void> updateReportDetails({
    required String reportId,
    String? organizationName,
    String? fboName,
    String? location,
    String? auditorName,
    String? date,
    String? fssaiNumber,
  }) async {
    final report = await getReport(reportId);
    if (report != null) {
      final updatedReport = report.copyWith(
        organizationName: organizationName,
        fboName: fboName,
        location: location,
        auditorName: auditorName,
        date: date,
        fssaiNumber: fssaiNumber,
        lastModified: DateTime.now(),
      );

      await saveReport(updatedReport);
    }
  }

  // No longer need close method - Firestore manages connections automatically
}
