import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Destinations
  Stream<QuerySnapshot> getDestinations() {
    return _db.collection('destinations').snapshots();
  }

  Future<DocumentSnapshot> getDestination(String id) {
    return _db.collection('destinations').doc(id).get();
  }

  Future<void> addDestination(Map<String, dynamic> data) {
    return _db.collection('destinations').add(data);
  }

  // Users
  Future<DocumentSnapshot> getUser(String userId) {
    return _db.collection('users').doc(userId).get();
  }

  Future<void> createUser(String userId, Map<String, dynamic> data) {
    return _db.collection('users').doc(userId).set(data);
  }

  Future<void> updateUserPoints(String userId, int points) {
    return _db.collection('users').doc(userId).update({
      'points': FieldValue.increment(points),
    });
  }

  // Check-ins
  Future<void> addCheckIn(Map<String, dynamic> data) {
    return _db.collection('check_ins').add(data);
  }

  Stream<QuerySnapshot> getUserCheckIns(String userId) {
    return _db
        .collection('check_ins')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Reports
  Future<void> addReport(Map<String, dynamic> data) {
    return _db.collection('reports').add(data);
  }

  Stream<QuerySnapshot> getReports() {
    return _db
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> updateReportStatus(String reportId, String status) {
    return _db.collection('reports').doc(reportId).update({
      'status': status,
    });
  }
}
