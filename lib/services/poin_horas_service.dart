import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class PoinHorasService {
  static final _db = FirebaseFirestore.instance;

  // ── Poin Horas constants ──────────────────────────────────────────────────
  static const int poinSubmitLaporan  = 5;
  static const int poinLaporanSelesai = 20;
  static const int poinSpamPenalty    = -10;
  static const int poinCheckIn        = 50;

  // ── XP constants ─────────────────────────────────────────────────────────
  static const int xpSubmitLaporan    = 15;
  static const int xpLaporanSelesai   = 75;
  static const int xpComment          = 10;
  static const int xpCheckIn          = 100;

  // ── Core method ─────────────────────────────────────────────────────────────

  /// Award or deduct poinHoras and XP independently.
  /// [amount] = poinHoras delta (can be negative).
  /// [xp] = XP delta; defaults to [amount] when positive, 0 otherwise.
  /// Returns the new level name if a level-up occurred, null otherwise.
  static Future<String?> award({
    required String userId,
    required int amount,
    required String type,
    required String description,
    String? relatedReportId,
    int? xp,
  }) async {
    final userRef = _db.collection('users').doc(userId);
    String? levelUpTo;

    await _db.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final data = snap.data() ?? {};

      final oldPoin  = (data['poinHoras']  as int?) ?? 0;
      final oldXP    = (data['currentXP']  as int?) ?? 0;
      final oldLevel = (data['level']      as String?) ?? 'Pemula';

      // poinHoras can be deducted (clamped to 0), XP only ever increases
      final xpDelta  = xp ?? (amount > 0 ? amount : 0);
      final newPoin  = (oldPoin + amount).clamp(0, 999999);
      final newXP    = xpDelta > 0 ? oldXP + xpDelta : oldXP;
      final newLevel = UserProfile.levelFromXP(newXP);

      if (xpDelta > 0 && newLevel != oldLevel) levelUpTo = newLevel;

      tx.update(userRef, {
        'poinHoras': newPoin,
        'currentXP': newXP,
        'level':     newLevel,
      });
    });

    // Log the transaction outside the Firestore transaction
    await _db.collection('poin_transactions').add({
      'userId':          userId,
      'amount':          amount,
      'type':            type,
      'description':     description,
      'relatedReportId': relatedReportId,
      'createdAt':       FieldValue.serverTimestamp(),
    });

    return levelUpTo;
  }

  // ── Convenience wrappers ────────────────────────────────────────────────────

  static Future<String?> awardForSubmit(String userId, String reportId) => award(
        userId:          userId,
        amount:          poinSubmitLaporan,
        xp:              xpSubmitLaporan,
        type:            'laporan_submit',
        description:     'Laporan baru dikirimkan',
        relatedReportId: reportId,
      );

  static Future<String?> awardForResolved(String userId, String reportId) => award(
        userId:          userId,
        amount:          poinLaporanSelesai,
        xp:              xpLaporanSelesai,
        type:            'laporan_selesai',
        description:     'Laporan berhasil diselesaikan',
        relatedReportId: reportId,
      );

  static Future<void> penalizeForSpam(String userId, String reportId) => award(
        userId:          userId,
        amount:          poinSpamPenalty,
        type:            'spam_penalty',
        description:     'Laporan dihapus karena spam/tidak valid',
        relatedReportId: reportId,
      );

  // ── Current user balance ────────────────────────────────────────────────────

  static Stream<int> watchBalance() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => (doc.data()?['poinHoras'] as int?) ?? 0);
  }
}
