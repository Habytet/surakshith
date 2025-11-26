import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload image to Firebase Storage and return download URL
  /// Returns null if upload fails
  Future<String?> uploadReportImage({
    required String reportId,
    required File imageFile,
  }) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = _storage.ref().child('reports/$reportId/images/$fileName.jpg');

      final uploadTask = ref.putFile(imageFile);

      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          uploadTask.cancel();
          throw Exception('Upload timeout');
        },
      );

      if (snapshot.state == TaskState.success) {
        final downloadUrl = await ref.getDownloadURL();
        return downloadUrl;
      }

      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Delete image from Firebase Storage
  Future<bool> deleteReportImage({required String imageUrl}) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete().timeout(const Duration(seconds: 10));
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// Delete all images for a report
  Future<bool> deleteAllReportImages({required String reportId}) async {
    try {
      final ref = _storage.ref().child('reports/$reportId/images');
      final listResult = await ref.listAll().timeout(const Duration(seconds: 10));

      for (var item in listResult.items) {
        await item.delete();
      }

      return true;
    } catch (e) {
      print('Error deleting all report images: $e');
      return false;
    }
  }

  /// Upload audit entry image to Firebase Storage and return download URL
  /// Returns null if upload fails after all retry attempts
  /// Retries 3 times with exponential backoff on failure
  Future<String?> uploadAuditEntryImage({
    required String reportId,
    required String entryId,
    required File imageFile,
  }) async {
    const maxRetries = 3;
    const baseTimeout = Duration(seconds: 30);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final ref = _storage
            .ref()
            .child('reports/$reportId/audit_entries/$entryId/images/$fileName.jpg');

        final uploadTask = ref.putFile(imageFile);

        final snapshot = await uploadTask.timeout(
          baseTimeout,
          onTimeout: () {
            uploadTask.cancel();
            throw Exception('Upload timeout after ${baseTimeout.inSeconds}s');
          },
        );

        if (snapshot.state == TaskState.success) {
          final downloadUrl = await ref.getDownloadURL();
          print('✅ Audit entry image uploaded successfully on attempt $attempt');
          return downloadUrl;
        }

        return null;
      } catch (e) {
        print('❌ Error uploading audit entry image (attempt $attempt/$maxRetries): $e');

        // If this was the last attempt, give up
        if (attempt == maxRetries) {
          print('🔴 Failed to upload audit entry image after $maxRetries attempts');
          return null;
        }

        // Wait before retrying (exponential backoff: 2s, 4s, 8s)
        final waitTime = Duration(seconds: 2 * attempt);
        print('⏳ Retrying in ${waitTime.inSeconds}s...');
        await Future.delayed(waitTime);
      }
    }

    return null;
  }

  /// Delete all images for an audit entry
  Future<bool> deleteAllAuditEntryImages({
    required String reportId,
    required String entryId,
  }) async {
    try {
      final ref = _storage
          .ref()
          .child('reports/$reportId/audit_entries/$entryId/images');
      final listResult = await ref.listAll().timeout(const Duration(seconds: 10));

      for (var item in listResult.items) {
        await item.delete();
      }

      return true;
    } catch (e) {
      print('Error deleting all audit entry images: $e');
      return false;
    }
  }
}
