import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/medan_reports.dart';

class UploadReports {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> uploadToFirestore() async {
    try {
      print('🚀 Starting upload reports to Firestore...');
      
      final batch = _firestore.batch();
      int count = 0;

      for (var report in medanReports) {
        final docRef = _firestore.collection('reports').doc();
        
        // Parse date string to DateTime
        final reportedAt = DateTime.parse(report['reportedAt'] as String);
        final status = report['status'] as String;
        
        // Set timeline based on status
        DateTime? processedAt;
        DateTime? completedAt;
        
        if (status == 'Diproses' || status == 'Selesai') {
          processedAt = reportedAt.add(const Duration(hours: 24));
        }
        
        if (status == 'Selesai') {
          completedAt = reportedAt.add(const Duration(days: 3));
        }
        
        batch.set(docRef, {
          'title': report['title'],
          'category': report['category'],
          'description': report['description'],
          'latitude': report['latitude'],
          'longitude': report['longitude'],
          'address': report['address'],
          'imageUrl': report['imageUrl'],
          'status': status,
          'upvotes': report['upvotes'],
          'upvotedBy': [], // Empty array for upvoted user IDs
          'reporterName': report['reporterName'],
          'reportedAt': Timestamp.fromDate(reportedAt),
          'processedAt': processedAt != null ? Timestamp.fromDate(processedAt) : null,
          'completedAt': completedAt != null ? Timestamp.fromDate(completedAt) : null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isActive': true,
          'userId': 'dummy_user', // Placeholder
        });
        
        count++;
        print('✅ Added: ${report['title']}');
      }

      await batch.commit();
      print('🎉 Successfully uploaded $count reports to Firestore!');
      
    } catch (e) {
      print('❌ Error uploading reports: $e');
      rethrow;
    }
  }

  Future<void> clearReports() async {
    try {
      print('🗑️ Clearing existing reports...');
      
      final snapshot = await _firestore.collection('reports').get();
      final batch = _firestore.batch();
      
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('✅ Cleared ${snapshot.docs.length} reports');
      
    } catch (e) {
      print('❌ Error clearing reports: $e');
      rethrow;
    }
  }

  Future<void> resetAndUpload() async {
    await clearReports();
    await uploadToFirestore();
  }
}
