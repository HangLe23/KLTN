import 'package:client/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<NodeItem>> getNodes() {
    return _db.collection('Node').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => NodeItem.fromFirestore(doc)).toList());
  }
}
