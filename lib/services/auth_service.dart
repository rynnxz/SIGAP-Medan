import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Create user in Firestore
  Future<void> createUserInFirestore(String userId, String name, String email) async {
    final emailVerified = _auth.currentUser?.emailVerified ?? false;
    await _firestoreService.createUser(
      userId,
      {
        'name': name,
        'email': email,
        'level': 'Pemula',
        'badges': [],
        'achievements': [],
        'currentXP': 0,
        'poinHoras': 0,
        'totalCheckIns': 0,
        'totalReports': 0,
        'totalComments': 0,
        'totalUpvotes': 0,
        'helpfulVotes': 0,
        'streakDays': 0,
        'reputation': 0,
        'accountType': 'user',
        'isVerified': emailVerified,
        'isModerator': false,
        'notificationsEnabled': true,
        'emailNotifications': true,
        'locationSharingEnabled': true,
        'preferredLanguage': 'id',
        'city': 'Medan',
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      },
    );
  }

  // Anonymous Sign In (untuk MVP - user bisa langsung pakai tanpa register)
  Future<UserCredential> signInAnonymously() async {
    final userCredential = await _auth.signInAnonymously();
    
    // Create user document in Firestore
    if (userCredential.user != null) {
      await createUserInFirestore(
        userCredential.user!.uid,
        'Guest User',
        '',
      );
    }
    
    return userCredential;
  }

  // Email/Password Sign Up (untuk future)
  Future<UserCredential> signUpWithEmail(String email, String password, String name) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    if (userCredential.user != null) {
      await createUserInFirestore(
        userCredential.user!.uid,
        name,
        email,
      );
    }
    
    return userCredential;
  }

  // Email/Password Sign In
  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign Out
  Future<void> signOut() {
    return _auth.signOut();
  }
}
