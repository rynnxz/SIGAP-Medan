import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/medan_quests.dart';

class UploadQuests {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> uploadToFirestore() async {
    try {
      print('🚀 Starting quest upload to Firestore...');

      // Upload quests
      final batch = _firestore.batch();
      int questCount = 0;

      for (var quest in MedanQuests.quests) {
        final docRef = _firestore.collection('quests').doc(quest['id']);
        batch.set(docRef, {
          ...quest,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
        questCount++;
      }

      await batch.commit();
      print('✅ Uploaded $questCount quests');

      // Upload badges as a single document for easy reference
      await _firestore.collection('system').doc('badges').set({
        'badges': MedanQuests.badges,
        'updated_at': FieldValue.serverTimestamp(),
      });
      print('✅ Uploaded ${MedanQuests.badges.length} badge definitions');

      print('🎉 Quest upload completed successfully!');
    } catch (e) {
      print('❌ Error uploading quests: $e');
      rethrow;
    }
  }

  // Helper method to reset all quests (for testing)
  Future<void> deleteAllQuests() async {
    try {
      print('🗑️ Deleting all quests...');
      
      final questsSnapshot = await _firestore.collection('quests').get();
      final batch = _firestore.batch();
      
      for (var doc in questsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('✅ Deleted ${questsSnapshot.docs.length} quests');
    } catch (e) {
      print('❌ Error deleting quests: $e');
      rethrow;
    }
  }
}
