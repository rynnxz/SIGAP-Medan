import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? phoneNumber;
  final String? bio;
  final String? address;
  final String? district; // Kecamatan
  final String? city; // Kota (default: Medan)
  
  // Gamification
  final int currentXP;
  final String level;
  final int poinHoras;
  final int streakDays;
  final DateTime? lastCheckIn;
  final List<String> badges;
  final List<String> achievements;
  
  // Activity Stats
  final int totalReports;
  final int totalCheckIns;
  final int totalUpvotes;
  final int totalComments;
  final int reportsResolved; // Laporan yang diselesaikan
  final int helpfulVotes; // Berapa kali laporan user di-upvote orang lain
  
  // Preferences
  final bool notificationsEnabled;
  final bool emailNotifications;
  final String preferredLanguage;
  final bool locationSharingEnabled;
  
  // Social
  final List<String> following; // User IDs yang difollow
  final List<String> followers; // User IDs yang follow user ini
  final int reputation; // Reputation score
  
  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActiveAt;
  final bool isVerified; // Verified citizen (auto after activity threshold)
  final bool phoneVerified; // Phone number verified via OTP
  final bool isModerator; // Community moderator
  final String accountType; // 'citizen', 'moderator', 'admin'

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.phoneNumber,
    this.bio,
    this.address,
    this.district,
    this.city = 'Medan',
    this.currentXP = 0,
    this.level = 'Pemula',
    this.poinHoras = 0,
    this.streakDays = 0,
    this.lastCheckIn,
    this.badges = const [],
    this.achievements = const [],
    this.totalReports = 0,
    this.totalCheckIns = 0,
    this.totalUpvotes = 0,
    this.totalComments = 0,
    this.reportsResolved = 0,
    this.helpfulVotes = 0,
    this.notificationsEnabled = true,
    this.emailNotifications = true,
    this.preferredLanguage = 'id',
    this.locationSharingEnabled = true,
    this.following = const [],
    this.followers = const [],
    this.reputation = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastActiveAt,
    this.isVerified = false,
    this.phoneVerified = false,
    this.isModerator = false,
    this.accountType = 'citizen',
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // ── Level thresholds ────────────────────────────────────────────────────────
  // Pemula 0-199 | Penjelajah 200-499 | Relawan 500-999
  // Detektif Kota 1000-1999 | Penjaga Kota 2000+

  static String levelFromXP(int xp) {
    if (xp >= 2000) return 'Penjaga Kota';
    if (xp >= 1000) return 'Detektif Kota';
    if (xp >= 500)  return 'Relawan';
    if (xp >= 200)  return 'Penjelajah';
    return 'Pemula';
  }

  int get levelMinXP {
    if (currentXP >= 2000) return ((currentXP - 2000) ~/ 1000) * 1000 + 2000;
    if (currentXP >= 1000) return 1000;
    if (currentXP >= 500)  return 500;
    if (currentXP >= 200)  return 200;
    return 0;
  }

  // XP needed to reach the next level (= top of current level bracket)
  int get maxXP {
    if (currentXP >= 2000) return levelMinXP + 1000;
    if (currentXP >= 1000) return 2000;
    if (currentXP >= 500)  return 1000;
    if (currentXP >= 200)  return 500;
    return 200;
  }

  // Progress within the current level bracket (0.0 – 1.0)
  double get progressPercentage =>
      ((currentXP - levelMinXP) / (maxXP - levelMinXP)).clamp(0.0, 1.0);
  
  // Check if user can create reports (must be verified)
  bool get canCreateReports => isVerified;
  
  // Check if user needs phone verification
  bool get needsPhoneVerification => !phoneVerified;
  
  // Check if user is close to verification (activity-based)
  bool get isCloseToVerification {
    if (isVerified) return false;
    // Need at least 50 XP OR 5 check-ins to be verified
    return currentXP >= 50 || totalCheckIns >= 5;
  }
  
  // Get verification progress message
  String get verificationProgressMessage {
    if (isVerified) return 'Akun Terverifikasi';
    if (!phoneVerified) return 'Verifikasi nomor HP untuk mulai';
    
    final xpNeeded = 50 - currentXP;
    final checkInsNeeded = 5 - totalCheckIns;
    
    if (xpNeeded <= 0 || checkInsNeeded <= 0) {
      return 'Hampir terverifikasi!';
    }
    
    return 'Butuh $xpNeeded XP atau $checkInsNeeded check-in lagi';
  }

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      phoneNumber: data['phoneNumber'],
      bio: data['bio'],
      address: data['address'],
      district: data['district'],
      city: data['city'] ?? 'Medan',
      currentXP: data['currentXP'] ?? 0,
      level: data['level'] ?? 'Pemula',
      poinHoras: data['poinHoras'] ?? 0,
      streakDays: data['streakDays'] ?? 0,
      lastCheckIn: data['lastCheckIn'] != null
          ? (data['lastCheckIn'] as Timestamp).toDate()
          : null,
      badges: List<String>.from(data['badges'] ?? []),
      achievements: List<String>.from(data['achievements'] ?? []),
      totalReports: data['totalReports'] ?? 0,
      totalCheckIns: data['totalCheckIns'] ?? 0,
      totalUpvotes: data['totalUpvotes'] ?? 0,
      totalComments: data['totalComments'] ?? 0,
      reportsResolved: data['reportsResolved'] ?? 0,
      helpfulVotes: data['helpfulVotes'] ?? 0,
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      emailNotifications: data['emailNotifications'] ?? true,
      preferredLanguage: data['preferredLanguage'] ?? 'id',
      locationSharingEnabled: data['locationSharingEnabled'] ?? true,
      following: List<String>.from(data['following'] ?? []),
      followers: List<String>.from(data['followers'] ?? []),
      reputation: data['reputation'] ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastActiveAt: data['lastActiveAt'] != null
          ? (data['lastActiveAt'] as Timestamp).toDate()
          : null,
      isVerified: data['isVerified'] ?? false,
      phoneVerified: data['phoneVerified'] ?? false,
      isModerator: data['isModerator'] ?? false,
      accountType: data['accountType'] ?? 'citizen',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'bio': bio,
      'address': address,
      'district': district,
      'city': city,
      'currentXP': currentXP,
      'level': level,
      'poinHoras': poinHoras,
      'streakDays': streakDays,
      'lastCheckIn': lastCheckIn != null ? Timestamp.fromDate(lastCheckIn!) : null,
      'badges': badges,
      'achievements': achievements,
      'totalReports': totalReports,
      'totalCheckIns': totalCheckIns,
      'totalUpvotes': totalUpvotes,
      'totalComments': totalComments,
      'reportsResolved': reportsResolved,
      'helpfulVotes': helpfulVotes,
      'notificationsEnabled': notificationsEnabled,
      'emailNotifications': emailNotifications,
      'preferredLanguage': preferredLanguage,
      'locationSharingEnabled': locationSharingEnabled,
      'following': following,
      'followers': followers,
      'reputation': reputation,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastActiveAt': lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
      'isVerified': isVerified,
      'phoneVerified': phoneVerified,
      'isModerator': isModerator,
      'accountType': accountType,
    };
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? photoUrl,
    String? phoneNumber,
    String? bio,
    String? address,
    String? district,
    String? city,
    int? currentXP,
    String? level,
    int? poinHoras,
    int? streakDays,
    DateTime? lastCheckIn,
    int? totalReports,
    int? totalCheckIns,
    int? totalUpvotes,
    int? totalComments,
    int? reportsResolved,
    int? helpfulVotes,
    List<String>? badges,
    List<String>? achievements,
    bool? notificationsEnabled,
    bool? emailNotifications,
    String? preferredLanguage,
    bool? locationSharingEnabled,
    List<String>? following,
    List<String>? followers,
    int? reputation,
    DateTime? lastActiveAt,
    bool? isVerified,
    bool? isModerator,
    String? accountType,
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bio: bio ?? this.bio,
      address: address ?? this.address,
      district: district ?? this.district,
      city: city ?? this.city,
      currentXP: currentXP ?? this.currentXP,
      level: level ?? this.level,
      poinHoras: poinHoras ?? this.poinHoras,
      streakDays: streakDays ?? this.streakDays,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      totalReports: totalReports ?? this.totalReports,
      totalCheckIns: totalCheckIns ?? this.totalCheckIns,
      totalUpvotes: totalUpvotes ?? this.totalUpvotes,
      totalComments: totalComments ?? this.totalComments,
      reportsResolved: reportsResolved ?? this.reportsResolved,
      helpfulVotes: helpfulVotes ?? this.helpfulVotes,
      badges: badges ?? this.badges,
      achievements: achievements ?? this.achievements,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      locationSharingEnabled: locationSharingEnabled ?? this.locationSharingEnabled,
      following: following ?? this.following,
      followers: followers ?? this.followers,
      reputation: reputation ?? this.reputation,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isVerified: isVerified ?? this.isVerified,
      isModerator: isModerator ?? this.isModerator,
      accountType: accountType ?? this.accountType,
    );
  }
}
