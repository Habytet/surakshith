import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surakshith/data/models/project_model.dart';

class ProjectRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize repository (no longer needed, but keeping for API compatibility)
  Future<void> init() async {
    // Firestore doesn't need initialization
    // Offline persistence is enabled globally in main.dart
  }

  // Get projects for a specific client as a reference
  CollectionReference _getProjectsCollection(String clientId) {
    return _firestore
        .collection('clients')
        .doc(clientId)
        .collection('projects');
  }

  // Get all projects across all clients as a Stream (real-time updates!)
  // Uses collectionGroup to query all 'projects' subcollections
  Stream<List<ProjectModel>> getAllProjectsStream() {
    return _firestore.collectionGroup('projects').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data();
                // Ensure clientId is set from the document path
                // Path format: clients/{clientId}/projects/{projectId}
                final pathSegments = doc.reference.path.split('/');
                if (pathSegments.length >= 2) {
                  data['clientId'] = pathSegments[1];
                }
                return ProjectModel.fromMap(data);
              })
              .toList(),
        );
  }

  // Get projects for a specific client as a Stream (real-time updates!)
  Stream<List<ProjectModel>> getProjectsByClientStream(String clientId) {
    return _getProjectsCollection(clientId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['clientId'] = clientId; // Ensure clientId is set
                return ProjectModel.fromMap(data);
              })
              .toList(),
        );
  }

  // Get all projects (one-time fetch for compatibility)
  Future<List<ProjectModel>> getAllProjects() async {
    try {
      final snapshot = await _firestore.collectionGroup('projects').get();
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            // Extract clientId from document path
            final pathSegments = doc.reference.path.split('/');
            if (pathSegments.length >= 2) {
              data['clientId'] = pathSegments[1];
            }
            return ProjectModel.fromMap(data);
          })
          .toList();
    } catch (e) {
      // If offline, Firestore will return cached data automatically
      rethrow;
    }
  }

  // Get projects by client (one-time fetch for compatibility)
  Future<List<ProjectModel>> getProjectsByClient(String clientId) async {
    try {
      final snapshot = await _getProjectsCollection(clientId).get();
      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['clientId'] = clientId;
            return ProjectModel.fromMap(data);
          })
          .toList();
    } catch (e) {
      // If offline, Firestore will return cached data automatically
      rethrow;
    }
  }

  // Add project (stores in Firestore subcollection)
  // Firestore offline persistence handles local caching automatically
  Future<void> addProject({
    required String clientId,
    required String name,
    String? contactName,
  }) async {
    // Generate unique ID
    final docRef = _getProjectsCollection(clientId).doc();
    final projectId = docRef.id;

    final project = ProjectModel(
      id: projectId,
      name: name,
      clientId: clientId,
      contactName: contactName,
      createdAt: DateTime.now(),
    );

    // Write to Firestore subcollection
    // If offline, this will be cached locally and synced automatically when online
    await docRef.set(project.toMap());
  }

  // Update project (updates in Firestore subcollection)
  // Firestore offline persistence handles local caching automatically
  Future<void> updateProject({
    required String clientId,
    required String id,
    required String name,
    String? contactName,
  }) async {
    // Update in Firestore subcollection
    // If offline, this will be cached locally and synced automatically when online
    await _getProjectsCollection(clientId).doc(id).update({
      'name': name,
      'contactName': contactName,
    });
  }

  // Delete project (deletes from Firestore subcollection)
  // Firestore offline persistence handles local caching automatically
  Future<void> deleteProject({
    required String clientId,
    required String id,
  }) async {
    // Delete from Firestore subcollection
    // If offline, this will be cached locally and synced automatically when online
    await _getProjectsCollection(clientId).doc(id).delete();
  }

  // No longer need manual sync methods!
  // Firestore handles all syncing automatically with offline persistence
}
