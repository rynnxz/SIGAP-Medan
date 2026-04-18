import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmTokenService {
  static final _db = FirebaseFirestore.instance;

  /// Simpan FCM token ke Firestore dan daftarkan listener refresh token.
  /// Panggil setelah user login (non-anonymous).
  static Future<void> saveToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _db.collection('users').doc(uid).update({'fcmToken': token});

      // Otomatis perbarui token jika FCM me-refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _db
            .collection('users')
            .doc(uid)
            .update({'fcmToken': newToken}).catchError((_) {});
      });
    } catch (_) {
      // Tidak kritis — abaikan jika gagal
    }
  }

  /// Hapus token saat logout agar push tidak terkirim ke device yang sudah keluar.
  static Future<void> clearToken(String uid) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .update({'fcmToken': FieldValue.delete()});
    } catch (_) {}
  }
}
