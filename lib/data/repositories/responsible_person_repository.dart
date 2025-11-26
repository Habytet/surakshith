import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surakshith/data/models/responsible_person_model.dart';

class ResponsiblePersonRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _responsiblePersonsCollection =
      FirebaseFirestore.instance.collection('responsible_persons');

  // Initialize repository (no longer needed, but keeping for API compatibility)
  Future<void> init() async {
    // Firestore doesn't need initialization
    // Offline persistence is enabled globally in main.dart
  }

  // Get all responsible persons as a Stream (real-time updates!)
  Stream<List<ResponsiblePersonModel>> getResponsiblePersonsStream() {
    return _responsiblePersonsCollection.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => ResponsiblePersonModel.fromMap(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  // Get all responsible persons (one-time fetch for compatibility)
  Future<List<ResponsiblePersonModel>> getAllResponsiblePersons() async {
    try {
      final snapshot = await _responsiblePersonsCollection.get();
      return snapshot.docs
          .map((doc) => ResponsiblePersonModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If offline, Firestore will return cached data automatically
      rethrow;
    }
  }

  // Add responsible person (stores in Firestore)
  // Firestore offline persistence handles local caching automatically
  Future<void> addResponsiblePerson({required String name}) async {
    // Generate unique ID
    final docRef = _responsiblePersonsCollection.doc();
    final responsiblePersonId = docRef.id;

    final responsiblePerson = ResponsiblePersonModel(
      id: responsiblePersonId,
      name: name,
      createdAt: DateTime.now(),
    );

    // Write to Firestore
    // If offline, this will be cached locally and synced automatically when online
    await docRef.set(responsiblePerson.toMap());
  }

  // Update responsible person (updates in Firestore)
  // Firestore offline persistence handles local caching automatically
  Future<void> updateResponsiblePerson({
    required String id,
    required String name,
  }) async {
    // Update in Firestore
    // If offline, this will be cached locally and synced automatically when online
    await _responsiblePersonsCollection.doc(id).update({
      'name': name,
    });
  }

  // Delete responsible person (deletes from Firestore)
  // Firestore offline persistence handles local caching automatically
  Future<void> deleteResponsiblePerson({required String id}) async {
    // Delete from Firestore
    // If offline, this will be cached locally and synced automatically when online
    await _responsiblePersonsCollection.doc(id).delete();
  }

  // No longer need manual sync methods!
  // Firestore handles all syncing automatically with offline persistence
}
