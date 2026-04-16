import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/medan_landmarks.dart';

class UploadLandmarks {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> uploadToFirestore() async {
    try {
      print('🚀 Starting upload to Firestore...');
      
      final batch = _firestore.batch();
      int count = 0;

      for (var landmark in medanLandmarks) {
        final docRef = _firestore.collection('destinations').doc();
        
        batch.set(docRef, {
          ...landmark,
          'favoritedBy': [], // Empty array for favorited user IDs
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });
        
        count++;
        print('✅ Added: ${landmark['name']}');
      }

      await batch.commit();
      print('🎉 Successfully uploaded $count landmarks to Firestore!');
      
    } catch (e) {
      print('❌ Error uploading landmarks: $e');
      rethrow;
    }
  }

  Future<void> clearDestinations() async {
    try {
      print('🗑️ Clearing existing destinations...');
      
      final snapshot = await _firestore.collection('destinations').get();
      final batch = _firestore.batch();
      
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('✅ Cleared ${snapshot.docs.length} destinations');
      
    } catch (e) {
      print('❌ Error clearing destinations: $e');
      rethrow;
    }
  }

  Future<void> resetAndUpload() async {
    await clearDestinations();
    await uploadToFirestore();
  }
}
