import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:surakshith/data/models/task_template_model.dart';

/// Repository for task templates (repetitive task patterns)
class TaskTemplateRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'taskTemplates';

  // ============================================
  // CREATE
  // ============================================

  /// Create a new task template
  Future<String?> createTemplate(TaskTemplateModel template) async {
    try {
      final docRef = await _firestore.collection(_collection).add(
            template.toFirestore(),
          );
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating task template: $e');
      return null;
    }
  }

  // ============================================
  // READ
  // ============================================

  /// Get all templates (real-time stream)
  Stream<List<TaskTemplateModel>> getAllTemplatesStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskTemplateModel.fromFirestore(doc))
            .toList());
  }

  /// Get templates for a specific client (real-time stream)
  Stream<List<TaskTemplateModel>> getTemplatesByClientStream(String clientId) {
    return _firestore
        .collection(_collection)
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskTemplateModel.fromFirestore(doc))
            .toList());
  }

  /// Get active templates for a client (real-time stream)
  Stream<List<TaskTemplateModel>> getActiveTemplatesByClientStream(
      String clientId) {
    return _firestore
        .collection(_collection)
        .where('clientId', isEqualTo: clientId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskTemplateModel.fromFirestore(doc))
            .toList());
  }

  /// Get templates by frequency
  Stream<List<TaskTemplateModel>> getTemplatesByFrequencyStream(
      RepeatFrequency frequency) {
    return _firestore
        .collection(_collection)
        .where('frequency', isEqualTo: frequency.name)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskTemplateModel.fromFirestore(doc))
            .toList());
  }

  /// Get single template by ID
  Future<TaskTemplateModel?> getTemplateById(String templateId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(templateId).get();
      if (doc.exists) {
        return TaskTemplateModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting template: $e');
      return null;
    }
  }

  /// Get templates that should generate tasks today
  Future<List<TaskTemplateModel>> getTemplatesForToday() async {
    try {
      // Get all active templates
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      final templates = snapshot.docs
          .map((doc) => TaskTemplateModel.fromFirestore(doc))
          .toList();

      // Filter templates that should generate today
      return templates.where((template) => template.shouldGenerateToday()).toList();
    } catch (e) {
      debugPrint('Error getting templates for today: $e');
      return [];
    }
  }

  // ============================================
  // UPDATE
  // ============================================

  /// Update a template
  Future<bool> updateTemplate(TaskTemplateModel template) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(template.id)
          .update(template.toFirestore());
      return true;
    } catch (e) {
      debugPrint('Error updating template: $e');
      return false;
    }
  }

  /// Update template's last generated timestamp
  Future<bool> updateLastGenerated(String templateId, DateTime dateTime) async {
    try {
      await _firestore.collection(_collection).doc(templateId).update({
        'lastGeneratedAt': Timestamp.fromDate(dateTime),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating last generated: $e');
      return false;
    }
  }

  /// Toggle template active status
  Future<bool> toggleTemplateActive(String templateId, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(templateId).update({
        'isActive': isActive,
      });
      return true;
    } catch (e) {
      debugPrint('Error toggling template: $e');
      return false;
    }
  }

  /// Update default assignees
  Future<bool> updateDefaultAssignees(
      String templateId, List<String> assignees) async {
    try {
      await _firestore.collection(_collection).doc(templateId).update({
        'defaultAssignees': assignees,
      });
      return true;
    } catch (e) {
      debugPrint('Error updating assignees: $e');
      return false;
    }
  }

  // ============================================
  // DELETE
  // ============================================

  /// Delete a template
  Future<bool> deleteTemplate(String templateId) async {
    try {
      await _firestore.collection(_collection).doc(templateId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting template: $e');
      return false;
    }
  }

  // ============================================
  // BATCH OPERATIONS
  // ============================================

  /// Bulk create templates
  Future<bool> bulkCreateTemplates(List<TaskTemplateModel> templates) async {
    try {
      final batch = _firestore.batch();

      for (final template in templates) {
        final docRef = _firestore.collection(_collection).doc();
        batch.set(docRef, template.toFirestore());
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error bulk creating templates: $e');
      return false;
    }
  }

  /// Deactivate all templates for a client
  Future<bool> deactivateClientTemplates(String clientId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('clientId', isEqualTo: clientId)
          .get();

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isActive': false});
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error deactivating templates: $e');
      return false;
    }
  }
}
