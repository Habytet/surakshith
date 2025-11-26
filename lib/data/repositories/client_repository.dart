import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:surakshith/data/models/client_model.dart';

class ClientRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reference to clients collection
  CollectionReference get _clientsCollection => _firestore.collection('clients');

  // Initialize repository (no longer needed, but keeping for API compatibility)
  Future<void> init() async {
    // Firestore doesn't need initialization
    // Offline persistence is enabled globally in main.dart
  }

  // Get all clients as a Stream (real-time updates!)
  Stream<List<ClientModel>> getClientsStream() {
    return _clientsCollection.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) =>
                  ClientModel.fromMap(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  // Get all clients as a one-time fetch (for compatibility)
  Future<List<ClientModel>> getAllClients() async {
    try {
      final snapshot = await _clientsCollection.get();
      return snapshot.docs
          .map((doc) => ClientModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If offline, Firestore will return cached data automatically
      rethrow;
    }
  }

  // Add client (stores in Firestore)
  // Firestore offline persistence handles local caching automatically
  Future<void> addClient({
    required String name,
    required String contactNumber,
    String? fssaiNumber,
  }) async {
    // Generate unique ID
    final docRef = _clientsCollection.doc();
    final clientId = docRef.id;

    final client = ClientModel(
      id: clientId,
      name: name,
      contactNumber: contactNumber,
      createdAt: DateTime.now(),
      fssaiNumber: fssaiNumber,
    );

    // Write to Firestore
    // If offline, this will be cached locally and synced automatically when online
    await docRef.set(client.toMap());
  }

  // Update client (updates in Firestore)
  // Firestore offline persistence handles local caching automatically
  Future<void> updateClient({
    required String id,
    required String name,
    required String contactNumber,
    String? fssaiNumber,
  }) async {
    // Update in Firestore
    // If offline, this will be cached locally and synced automatically when online
    await _clientsCollection.doc(id).update({
      'name': name,
      'contactNumber': contactNumber,
      'fssaiNumber': fssaiNumber,
    });
  }

  // Delete client (deletes from Firestore)
  // Firestore offline persistence handles local caching automatically
  Future<void> deleteClient({required String id}) async {
    // Delete from Firestore
    // If offline, this will be cached locally and synced automatically when online
    await _clientsCollection.doc(id).delete();
  }

  // No longer need manual sync methods!
  // Firestore handles all syncing automatically with offline persistence
}
