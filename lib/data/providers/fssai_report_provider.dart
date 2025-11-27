import 'dart:async';
import 'package:flutter/material.dart';
import 'package:surakshith/data/models/fssai_report_model.dart';
import 'package:surakshith/data/repositories/fssai_report_repository.dart';
import 'package:surakshith/data/constants/fssai_audit_points.dart';

class FssaiReportProvider extends ChangeNotifier {
  FssaiReportRepository? _repository;
  StreamSubscription<FssaiReportModel?>? _reportSubscription;

  bool _isLoading = false;
  String _errorMessage = '';
  bool _isInitialized = false;
  FssaiReportModel? _currentReport;
  String? _currentReportId;

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  FssaiReportModel? get currentReport => _currentReport;

  // Initialize
  Future<void> init() async {
    _repository = FssaiReportRepository();
    await _repository!.init();
    _isInitialized = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _reportSubscription?.cancel();
    super.dispose();
  }

  // Load or create report for a given reportId with real-time updates
  Future<void> loadReport(String reportId) async {
    if (_repository == null) {
      _setError('Repository not initialized');
      return;
    }

    // Cancel previous subscription if any
    await _reportSubscription?.cancel();

    _currentReportId = reportId;
    _setLoading(true);
    _clearError();

    try {
      // Check if report exists
      final existingReport = await _repository!.getReport(reportId);

      if (existingReport == null) {
        // Create new report with empty scores
        final newReport = FssaiReportModel(
          reportId: reportId,
          scores: {},
          lastModified: DateTime.now(),
        );
        await _repository!.saveReport(newReport);
      }

      // Subscribe to real-time updates
      _reportSubscription = _repository!.getReportStream(reportId).listen(
        (report) {
          _currentReport = report;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Error in FSSAI report stream: $error');
          _setError('Failed to load FSSAI report: $error');
        },
      );

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load FSSAI report: $e');
      _setLoading(false);
    }
  }

  // Update score for a specific audit point
  Future<void> updateScore(int serialNo, int score) async {
    if (_repository == null || _currentReportId == null) {
      _setError('No report loaded');
      return;
    }

    try {
      await _repository!.updateScore(_currentReportId!, serialNo, score);
      // Real-time listener will automatically update _currentReport
    } catch (e) {
      _setError('Failed to update score: $e');
    }
  }

  // Update report details (organization, FBO, etc.)
  Future<void> updateReportDetails({
    String? organizationName,
    String? fboName,
    String? location,
    String? auditorName,
    String? date,
    String? fssaiNumber,
  }) async {
    if (_repository == null || _currentReportId == null) {
      _setError('No report loaded');
      return;
    }

    try {
      await _repository!.updateReportDetails(
        reportId: _currentReportId!,
        organizationName: organizationName,
        fboName: fboName,
        location: location,
        auditorName: auditorName,
        date: date,
        fssaiNumber: fssaiNumber,
      );
      // Real-time listener will automatically update _currentReport
    } catch (e) {
      _setError('Failed to update report details: $e');
    }
  }

  // Get score for a specific audit point
  int getScore(int serialNo) {
    if (_currentReport == null) return 0;
    return _currentReport!.scores[serialNo] ?? 0;
  }

  // Get total score
  int get totalScore {
    if (_currentReport == null) return 0;
    return _currentReport!.totalScore;
  }

  // Get total max score
  int get totalMaxScore {
    return FssaiAuditPoints.totalMaxScore;
  }

  // Clear current report
  void clearCurrentReport() {
    _reportSubscription?.cancel();
    _currentReport = null;
    _currentReportId = null;
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
  }
}
