import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/dummy_data.dart';

class FirestoreMigration {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Migrate dummy destinations to Firestore
  Future<void> migrateDummyDestinations() async {
    final batch = _db.batch();
    
    for (var destination in dummyDestinations) {
      final docRef = _db.collection('destinations').doc();
      batch.set(docRef, {
        'name': destination['name'],
        'description': destination['description'],
        'category': destination['category'],
        'latitude': destination['latitude'],
        'longitude': destination['longitude'],
        'address': destination['address'],
        'imageUrl': destination['imageUrl'],
        'rating': destination['rating'],
        'reviews': destination['reviews'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    
    await batch.commit();
    print('✅ Migrated ${dummyDestinations.length} destinations');
  }

  // Check if destinations already exist
  Future<bool> hasDestinations() async {
    final snapshot = await _db.collection('destinations').limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  // Run migration if needed
  Future<void> runMigrationIfNeeded() async {
    final hasData = await hasDestinations();
    if (!hasData) {
      print('🔄 Running migration...');
      await migrateDummyDestinations();
    } else {
      print('✅ Data already exists, skipping migration');
    }
  }
}
