/// Simpan FCM token admin ke Firestore agar Cloud Function bisa kirim push.
///
/// Panggil [FcmTokenService.saveToken] setelah admin login.
/// Membutuhkan package: firebase_messaging: ^15.0.0 (tambah ke pubspec.yaml)
///
/// Contoh penggunaan di login screen setelah berhasil sign-in sebagai admin:
///   await FcmTokenService.saveToken(user.uid);

// ignore_for_file: depend_on_referenced_packages
// TODO: Uncomment setelah menambahkan firebase_messaging ke pubspec.yaml

// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class FcmTokenService {
//   static Future<void> saveToken(String uid) async {
//     final token = await FirebaseMessaging.instance.getToken();
//     if (token == null) return;
//     await FirebaseFirestore.instance
//         .collection('users')
//         .doc(uid)
//         .update({'fcmToken': token});
//   }
//
//   static Future<void> clearToken(String uid) async {
//     await FirebaseFirestore.instance
//         .collection('users')
//         .doc(uid)
//         .update({'fcmToken': null});
//   }
// }
