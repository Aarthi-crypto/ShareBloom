import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/resource_item.dart';

class FirestoreService {

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final CollectionReference _resources =
  FirebaseFirestore.instance.collection("resources");

  Future<void> addResource(ResourceItem item) async {

    final data = item.toMap();

    data["createdAt"] = FieldValue.serverTimestamp();
    data["status"] = "Available";

    await _resources.add(data);
  }

  Stream<List<ResourceItem>> getResources() {

    return _resources
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {

      return snapshot.docs.map((doc) {

        final data = doc.data() as Map<String, dynamic>;

        return ResourceItem.fromMap(
          doc.id,
          data,
        );

      }).toList();
    });
  }

  Stream<ResourceItem> getResourceById(String id) {

    return _resources.doc(id).snapshots().map((doc) {

      final data = doc.data() as Map<String, dynamic>;

      return ResourceItem.fromMap(
        doc.id,
        data,
      );
    });
  }

  Future<void> matchResource({
    required String resourceId,
    required String matchedWithEmail,
  }) async {

    await _resources.doc(resourceId).update({
      "status": "Pending",
      "matchedWithEmail": matchedWithEmail,
    });
  }

  Future<void> acceptResource({
    required String resourceId,
    required String acceptedByEmail,
  }) async {

    await _resources.doc(resourceId).update({
      "status": "Accepted",
      "acceptedByEmail": acceptedByEmail,
    });
  }

  Future<void> rejectResource({
    required String resourceId,
  }) async {

    await _resources.doc(resourceId).update({
      "status": "Rejected",
      "matchedWithEmail": null,
      "acceptedByEmail": null,
    });
  }

  Future<void> completeResource({
    required String resourceId,
  }) async {

    await _resources.doc(resourceId).update({
      "status": "Completed",
    });
  }

  Future<void> updateResource(
      String id,
      Map<String, dynamic> data,
      ) async {

    await _resources.doc(id).update(data);
  }
}