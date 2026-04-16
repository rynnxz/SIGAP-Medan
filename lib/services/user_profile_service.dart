import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user profile
  Stream<UserProfile?> getUserProfile() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    });
  }

  // Create or update user profile
  Future<void> createOrUpdateProfile({
    required String uid,
    required String name,
    required String email,
    String? photoUrl,
    String? phoneNumber,
    String? bio,
    String? address,
    String? district,
  }) async {
    final docRef = _firestore.collection('users').doc(uid);
    final doc = await docRef.get();

    if (doc.exists) {
      // Update existing profile
      await docRef.update({
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'phoneNumber': phoneNumber,
        'bio': bio,
        'address': address,
        'district': district,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Create new profile
      final profile = UserProfile(
        uid: uid,
        name: name,
        email: email,
        photoUrl: photoUrl,
        phoneNumber: phoneNumber,
        bio: bio,
        address: address,
        district: district,
      );
      await docRef.set(profile.toFirestore());
    }
  }

  // Add XP and update level
  Future<void> addXP(int xp) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();
    
    if (!doc.exists) return;

    final profile = UserProfile.fromFirestore(doc);
    int newXP = profile.currentXP + xp;
    int newPoinHoras = profile.poinHoras + xp;
    final newLevel = UserProfile.levelFromXP(newXP);

    await docRef.update({
      'currentXP': newXP,
      'poinHoras': newPoinHoras,
      'level': newLevel,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Daily login streak — call once per app session (uses lastActiveAt)
  // Returns the new streak count, or null if already counted today.
  Future<int?> updateLoginStreak() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();
    if (!doc.exists) return null;

    final profile = UserProfile.fromFirestore(doc);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int newStreak = profile.streakDays;

    if (profile.lastActiveAt != null) {
      final lastDay = DateTime(
        profile.lastActiveAt!.year,
        profile.lastActiveAt!.month,
        profile.lastActiveAt!.day,
      );
      final diff = today.difference(lastDay).inDays;
      if (diff == 0) {
        // Already counted today — just update timestamp, no streak change
        await docRef.update({'lastActiveAt': FieldValue.serverTimestamp()});
        return null;
      } else if (diff == 1) {
        newStreak++;
      } else {
        // Streak broken
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    await docRef.update({
      'streakDays': newStreak,
      'lastActiveAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return newStreak;
  }

  // Update streak (Jejak Kesawan check-in — keeps lastCheckIn separate)
  Future<void> updateStreak() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();
    
    if (!doc.exists) return;

    final profile = UserProfile.fromFirestore(doc);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    int newStreak = profile.streakDays;
    
    if (profile.lastCheckIn != null) {
      final lastCheckIn = DateTime(
        profile.lastCheckIn!.year,
        profile.lastCheckIn!.month,
        profile.lastCheckIn!.day,
      );
      
      final difference = today.difference(lastCheckIn).inDays;
      
      if (difference == 0) {
        // Already checked in today
        return;
      } else if (difference == 1) {
        // Consecutive day
        newStreak++;
      } else {
        // Streak broken
        newStreak = 1;
      }
    } else {
      // First check-in
      newStreak = 1;
    }

    await docRef.update({
      'streakDays': newStreak,
      'lastCheckIn': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Increment report count
  Future<void> incrementReports() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'totalReports': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Increment check-in count
  Future<void> incrementCheckIns() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'totalCheckIns': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Increment upvotes count
  Future<void> incrementUpvotes() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'totalUpvotes': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Increment comments count
  Future<void> incrementComments() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'totalComments': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Increment resolved reports count
  Future<void> incrementReportsResolved() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'reportsResolved': FieldValue.increment(1),
      'reputation': FieldValue.increment(10), // +10 reputation for resolved report
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Increment helpful votes (when someone upvotes your report)
  Future<void> incrementHelpfulVotes() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'helpfulVotes': FieldValue.increment(1),
      'reputation': FieldValue.increment(5), // +5 reputation for helpful vote
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Add achievement
  Future<void> addAchievement(String achievementId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'achievements': FieldValue.arrayUnion([achievementId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Follow user
  Future<void> followUser(String targetUserId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();

    // Add to current user's following list
    batch.update(_firestore.collection('users').doc(user.uid), {
      'following': FieldValue.arrayUnion([targetUserId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Add to target user's followers list
    batch.update(_firestore.collection('users').doc(targetUserId), {
      'followers': FieldValue.arrayUnion([user.uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Unfollow user
  Future<void> unfollowUser(String targetUserId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();

    // Remove from current user's following list
    batch.update(_firestore.collection('users').doc(user.uid), {
      'following': FieldValue.arrayRemove([targetUserId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Remove from target user's followers list
    batch.update(_firestore.collection('users').doc(targetUserId), {
      'followers': FieldValue.arrayRemove([user.uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Update notification preferences
  Future<void> updateNotificationPreferences({
    bool? notificationsEnabled,
    bool? emailNotifications,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (notificationsEnabled != null) {
      updates['notificationsEnabled'] = notificationsEnabled;
    }
    if (emailNotifications != null) {
      updates['emailNotifications'] = emailNotifications;
    }

    await _firestore.collection('users').doc(user.uid).update(updates);
  }

  // Update location sharing preference
  Future<void> updateLocationSharing(bool enabled) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'locationSharingEnabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update last active timestamp
  Future<void> updateLastActive() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'lastActiveAt': FieldValue.serverTimestamp(),
    });
  }

  // Add badge
  Future<void> addBadge(String badgeId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'badges': FieldValue.arrayUnion([badgeId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get leaderboard
  Future<List<UserProfile>> getLeaderboard({int limit = 10}) async {
    final snapshot = await _firestore
        .collection('users')
        .orderBy('poinHoras', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => UserProfile.fromFirestore(doc)).toList();
  }

  // Get user rank
  Future<int> getUserRank() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return 0;

    final userProfile = UserProfile.fromFirestore(userDoc);
    
    final higherRankedCount = await _firestore
        .collection('users')
        .where('poinHoras', isGreaterThan: userProfile.poinHoras)
        .count()
        .get();

    return higherRankedCount.count! + 1;
  }

  // Mark phone as verified
  Future<void> markPhoneVerified() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'phoneVerified': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Check and auto-verify user based on activity
  Future<void> checkAndAutoVerify() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();
    
    if (!doc.exists) return;

    final profile = UserProfile.fromFirestore(doc);
    
    // Skip if already verified or phone not verified
    if (profile.isVerified || !profile.phoneVerified) return;

    // Auto-verify if user has 50+ XP OR 5+ check-ins
    if (profile.currentXP >= 50 || profile.totalCheckIns >= 5) {
      await docRef.update({
        'isVerified': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add verified badge
      await addBadge('verified_citizen');
      
      // Add achievement
      await addAchievement('first_verification');
      
      // Bonus XP for verification
      await addXP(100);
    }
  }
}
