import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:surakshith/data/models/audit_area_entry_model.dart';
import 'package:surakshith/data/repositories/audit_area_entry_repository.dart';
import 'package:surakshith/data/services/storage_service.dart';

class AuditAreaEntryProvider extends ChangeNotifier {
  AuditAreaEntryRepository? _repository;
  final StorageService _storageService = StorageService();

  List<AuditAreaEntryModel> _allEntries = [];
  StreamSubscription<List<AuditAreaEntryModel>>? _entriesSubscription;

  bool _isLoading = false;
  String _errorMessage = '';
  bool _isInitialized = false;
  String? _currentReportId;

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  // Initialize with real-time Firestore stream
  Future<void> init() async {
    _repository = AuditAreaEntryRepository();
    await _repository!.init();

    // Subscribe to real-time entries stream
    _entriesSubscription = _repository!.getAllEntriesStream().listen(
      (entries) {
        _allEntries = entries;
        _isInitialized = true;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error in entries stream: $error');
        _setError('Failed to load entries: $error');
      },
    );
  }

  @override
  void dispose() {
    _entriesSubscription?.cancel();
    super.dispose();
  }

  // Set current report
  void setCurrentReport(String reportId) {
    _currentReportId = reportId;
    notifyListeners();
  }

  // Get all entries for current report (filtered locally)
  List<AuditAreaEntryModel> getEntriesForCurrentReport() {
    if (!_isInitialized || _currentReportId == null) {
      return [];
    }
    return _allEntries.where((e) => e.reportId == _currentReportId).toList();
  }

  // Get all entries
  List<AuditAreaEntryModel> getAllEntries() {
    if (!_isInitialized) {
      return [];
    }
    return _allEntries;
  }

  // Add entry (uploads images to Firebase Storage, then saves to Firestore)
  Future<String?> addEntry({
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
    List<File>? imageFiles, // max 2
  }) async {
    if (_repository == null) {
      _setError('Repository not initialized');
      return null;
    }

    // Validate max 2 images
    if (imageFiles != null && imageFiles.length > 2) {
      _setError('Maximum 2 images allowed per audit entry');
      return null;
    }

    _setLoading(true);
    _clearError();

    try {
      // Upload images to Firebase Storage first (if any)
      final imageUrls = <String>[];
      if (imageFiles != null && imageFiles.isNotEmpty) {
        // Generate temp entry ID for storage path
        final tempEntryId = DateTime.now().millisecondsSinceEpoch.toString();

        for (int i = 0; i < imageFiles.length; i++) {
          debugPrint('📤 Uploading image ${i + 1}/${imageFiles.length}...');
          final imageUrl = await _storageService.uploadAuditEntryImage(
            reportId: reportId,
            entryId: tempEntryId,
            imageFile: imageFiles[i],
          );
          if (imageUrl != null) {
            imageUrls.add(imageUrl);
            debugPrint('✅ Image ${i + 1} uploaded successfully');
          } else {
            debugPrint('❌ Image ${i + 1} failed to upload');
          }
        }
      }

      // Create entry in Firestore (automatically syncs to local cache)
      final entryId = await _repository!.addEntry(
        clientId: clientId,
        projectId: projectId,
        reportId: reportId,
        auditAreaId: auditAreaId,
        responsiblePersonId: responsiblePersonId,
        auditIssueIds: auditIssueIds,
        risk: risk,
        observation: observation,
        recommendation: recommendation,
        deadlineDate: deadlineDate,
        imageUrls: imageUrls,
      );

      debugPrint('✅ Entry created in Firestore');
      _setLoading(false);
      return entryId;
    } catch (e) {
      _setError('Failed to add entry: $e');
      _setLoading(false);
      return null;
    }
  }

  // Update entry (handles image uploads/deletes, then updates Firestore)
  Future<bool> updateEntry({
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
    List<File>? newImageFiles,
    List<String>? existingImageUrls,
  }) async {
    if (_repository == null) {
      _setError('Repository not initialized');
      return false;
    }

    // Get existing entry to check current images
    final existingEntry = _allEntries.firstWhere(
      (e) => e.id == id && e.reportId == reportId,
      orElse: () => throw Exception('Entry not found'),
    );

    // Calculate total images
    final existingCount = existingImageUrls?.length ?? 0;
    final newCount = newImageFiles?.length ?? 0;
    if (existingCount + newCount > 2) {
      _setError('Maximum 2 images allowed per audit entry');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Handle image changes
      List<String> finalImageUrls = existingImageUrls ?? existingEntry.imageUrls;

      // Delete removed images from Storage
      final removedImages = existingEntry.imageUrls
          .where((url) => !finalImageUrls.contains(url))
          .toList();
      for (final imageUrl in removedImages) {
        await _storageService.deleteReportImage(imageUrl: imageUrl);
        debugPrint('🗑️ Deleted removed image from Storage');
      }

      // Upload new images to Firebase Storage
      if (newImageFiles != null && newImageFiles.isNotEmpty) {
        for (int i = 0; i < newImageFiles.length; i++) {
          if (finalImageUrls.length >= 2) {
            debugPrint('⚠️ Skipping image ${i + 1} - max 2 images limit reached');
            break;
          }

          debugPrint('📤 Uploading new image ${i + 1}/${newImageFiles.length}...');
          final imageUrl = await _storageService.uploadAuditEntryImage(
            reportId: reportId,
            entryId: id,
            imageFile: newImageFiles[i],
          );
          if (imageUrl != null) {
            finalImageUrls.add(imageUrl);
            debugPrint('✅ New image ${i + 1} uploaded successfully');
          } else {
            debugPrint('❌ New image ${i + 1} failed to upload');
          }
        }
      }

      // Update entry in Firestore (automatically syncs to local cache)
      await _repository!.updateEntry(
        clientId: clientId,
        projectId: projectId,
        reportId: reportId,
        id: id,
        auditAreaId: auditAreaId,
        responsiblePersonId: responsiblePersonId,
        auditIssueIds: auditIssueIds,
        risk: risk,
        observation: observation,
        recommendation: recommendation,
        deadlineDate: deadlineDate,
        imageUrls: finalImageUrls,
      );

      debugPrint('✅ Entry updated in Firestore');
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update entry: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete entry
  Future<bool> deleteEntry({
    required String clientId,
    required String projectId,
    required String reportId,
    required String id,
  }) async {
    if (_repository == null) {
      _setError('Repository not initialized');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Delete images from Firebase Storage
      await _storageService.deleteAllAuditEntryImages(
          reportId: reportId, entryId: id);

      // Delete from Firestore (automatically removes from local cache)
      await _repository!.deleteEntry(
        clientId: clientId,
        projectId: projectId,
        reportId: reportId,
        id: id,
      );

      debugPrint('✅ Entry deleted from Firestore');
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete entry: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete single image from entry
  Future<bool> deleteImageFromEntry({
    required String clientId,
    required String projectId,
    required String reportId,
    required String entryId,
    required String imageUrl,
  }) async {
    if (_repository == null) {
      _setError('Repository not initialized');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Get current entry
      final entry = _allEntries.firstWhere(
        (e) => e.id == entryId && e.reportId == reportId,
        orElse: () => throw Exception('Entry not found'),
      );

      // Remove image URL from list
      final updatedImageUrls = List<String>.from(entry.imageUrls)
        ..remove(imageUrl);

      // Update entry in Firestore
      await _repository!.updateEntry(
        clientId: clientId,
        projectId: projectId,
        reportId: reportId,
        id: entryId,
        imageUrls: updatedImageUrls,
      );

      // Delete from Firebase Storage
      await _storageService.deleteReportImage(imageUrl: imageUrl);

      debugPrint('✅ Image deleted from entry');
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete image: $e');
      _setLoading(false);
      return false;
    }
  }

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
