import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:surakshith/data/models/report_model.dart';
import 'package:surakshith/data/repositories/report_repository.dart';
import 'package:surakshith/data/services/storage_service.dart';

class ReportProvider extends ChangeNotifier {
  ReportRepository? _reportRepository;
  final StorageService _storageService = StorageService();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isInitialized = false;
  String? _currentClientId;
  String? _currentProjectId;
  List<ReportModel> _allReports = [];
  StreamSubscription<List<ReportModel>>? _reportsSubscription;

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  // Initialize
  Future<void> init() async {
    _reportRepository = ReportRepository();
    await _reportRepository!.init();

    // Subscribe to real-time updates from Firestore (all reports across all projects)
    _reportsSubscription = _reportRepository!.getAllReportsStream().listen(
      (reports) {
        _allReports = reports;
        _isInitialized = true;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error in reports stream: $error');
        // Don't set error - offline mode will use cached data
      },
    );
  }

  @override
  void dispose() {
    _reportsSubscription?.cancel();
    super.dispose();
  }

  // Set current project (for filtering reports)
  Future<void> setCurrentProject(String clientId, String projectId) async {
    _currentClientId = clientId;
    _currentProjectId = projectId;
    // Reports are already loaded via real-time stream - just notify
    notifyListeners();
  }

  // Get all reports for current project (filtered from the cached list)
  List<ReportModel> getReportsForCurrentProject() {
    if (!_isInitialized ||
        _currentClientId == null ||
        _currentProjectId == null) {
      return [];
    }
    return _allReports
        .where((report) =>
            report.clientId == _currentClientId &&
            report.projectId == _currentProjectId)
        .toList();
  }

  // Get all reports (for filtering across all projects)
  List<ReportModel> getAllReports() {
    return _allReports;
  }

  // Add report
  Future<String?> addReport({
    required String clientId,
    required String projectId,
    required DateTime reportDate,
    String status = 'draft',
    String? contactName,
  }) async {
    if (_reportRepository == null) {
      _setError('Repository not initialized');
      return null;
    }

    _setLoading(true);
    _clearError();

    try {
      // Call repository
      // Firestore will automatically update the stream, which updates _allReports
      final reportId = await _reportRepository!.addReport(
        clientId: clientId,
        projectId: projectId,
        reportDate: reportDate,
        status: status,
        contactName: contactName,
      );

      _setLoading(false);
      return reportId;
    } catch (e) {
      _setError('Failed to create report: $e');
      _setLoading(false);
      return null;
    }
  }

  // Update report
  Future<bool> updateReport({
    required String clientId,
    required String projectId,
    required String id,
    DateTime? reportDate,
    String? status,
    List<String>? imageUrls,
    String? contactName,
  }) async {
    if (_reportRepository == null) {
      _setError('Repository not initialized');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Call repository
      // Firestore will automatically update the stream, which updates _allReports
      await _reportRepository!.updateReport(
        clientId: clientId,
        projectId: projectId,
        id: id,
        reportDate: reportDate,
        status: status,
        imageUrls: imageUrls,
        contactName: contactName,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update report: $e');
      _setLoading(false);
      return false;
    }
  }

  // Add image to report
  Future<bool> addImageToReport({
    required String clientId,
    required String projectId,
    required String reportId,
    required File imageFile,
  }) async {
    if (_reportRepository == null) {
      _setError('Repository not initialized');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Upload image to Firebase Storage
      final imageUrl = await _storageService.uploadReportImage(
        reportId: reportId,
        imageFile: imageFile,
      );

      if (imageUrl == null) {
        _setError('Failed to upload image');
        _setLoading(false);
        return false;
      }

      // Get current report from cache
      final report = _allReports.firstWhere(
        (r) => r.id == reportId,
        orElse: () => throw Exception('Report not found'),
      );

      // Add new image URL to existing list
      final updatedImageUrls = List<String>.from(report.imageUrls)..add(imageUrl);

      // Update report with new image URLs
      await _reportRepository!.updateReport(
        clientId: clientId,
        projectId: projectId,
        id: reportId,
        imageUrls: updatedImageUrls,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add image: $e');
      _setLoading(false);
      return false;
    }
  }

  // Remove image from report
  Future<bool> removeImageFromReport({
    required String clientId,
    required String projectId,
    required String reportId,
    required String imageUrl,
  }) async {
    if (_reportRepository == null) {
      _setError('Repository not initialized');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Get current report from cache
      final report = _allReports.firstWhere(
        (r) => r.id == reportId,
        orElse: () => throw Exception('Report not found'),
      );

      // Remove image URL from list
      final updatedImageUrls = List<String>.from(report.imageUrls)
        ..remove(imageUrl);

      // Update report with new image URLs
      await _reportRepository!.updateReport(
        clientId: clientId,
        projectId: projectId,
        id: reportId,
        imageUrls: updatedImageUrls,
      );

      // Delete from Firebase Storage
      await _storageService.deleteReportImage(imageUrl: imageUrl);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to remove image: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete report
  Future<bool> deleteReport({
    required String clientId,
    required String projectId,
    required String id,
  }) async {
    if (_reportRepository == null) {
      _setError('Repository not initialized');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Delete all images from Firebase Storage first
      await _storageService.deleteAllReportImages(reportId: id);

      // Call repository
      // Firestore will automatically update the stream, which updates _allReports
      await _reportRepository!.deleteReport(
        clientId: clientId,
        projectId: projectId,
        id: id,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete report: $e');
      _setLoading(false);
      return false;
    }
  }

  // No longer need manual sync!
  // Firestore real-time listeners + offline persistence handle everything automatically

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
}
