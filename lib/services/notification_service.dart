import 'package:flutter/material.dart' show Color;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId    = 'sigap_medan';
  static const _channelName  = 'SIGAP Medan';
  static const _channelDesc  = 'Notifikasi laporan dan reminder harian SIGAP Medan';

  static const _channelIdSos   = 'sos_alerts';
  static const _channelNameSos = 'SOS Darurat';
  static const _channelDescSos = 'Notifikasi sinyal darurat SOS dari pengguna';

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDesc,
    importance: Importance.high,
    playSound: true,
  );

  static bool _initialized = false;

  // ── Init ──────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelIdSos,
          _channelNameSos,
          description: _channelDescSos,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ));

    _initialized = true;
  }

  // ── Request permission (Android 13+) ─────────────────────────────────────

  static Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ── Show immediate local notification ────────────────────────────────────

  static Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  // ── SOS alert notification (admin only) ─────────────────────────────────

  static Future<void> showSosNotification({
    required String alertId,
    required String userName,
    required String category,
  }) async {
    await _plugin.show(
      alertId.hashCode.abs(),
      '🚨 SOS Darurat!',
      '$userName mengirim sinyal: $category',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelIdSos,
          _channelNameSos,
          channelDescription: _channelDescSos,
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFEF4444),
          fullScreenIntent: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ── Schedule daily streak reminder at 20:00 WIB ───────────────────────────

  static Future<void> scheduleStreakReminder() async {
    await _plugin.cancel(999);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      20, // 20:00 WIB
      0,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      999,
      '🔥 Jaga Streakmu!',
      'Buka SIGAP Medan hari ini untuk menjaga streak harianmu.',
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Cancel streak reminder ─────────────────────────────────────────────────

  static Future<void> cancelStreakReminder() async {
    await _plugin.cancel(999);
  }

  // ── FCM foreground listener ───────────────────────────────────────────────

  /// Panggil sekali setelah [init] — menampilkan notifikasi lokal
  /// saat pesan FCM datang ketika app sedang terbuka (foreground).
  static void initFCM() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showFromRemoteMessage(message);
    });
  }

  /// Tampilkan local notification dari payload FCM (foreground & background).
  static Future<void> showFromRemoteMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final isSos = message.data['type'] == 'sos_alert';

    await _plugin.show(
      message.hashCode.abs() % 100000,
      notification.title ?? 'SIGAP Medan',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          isSos ? _channelIdSos : _channelId,
          isSos ? _channelNameSos : _channelName,
          channelDescription:
              isSos ? _channelDescSos : _channelDesc,
          importance: isSos ? Importance.max : Importance.high,
          priority: isSos ? Priority.max : Priority.high,
          icon: '@mipmap/ic_launcher',
          color: isSos ? const Color(0xFFEF4444) : const Color(0xFF10B981),
          enableVibration: true,
          fullScreenIntent: isSos,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ── Write notification record to Firestore ────────────────────────────────

  static Future<void> writeNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? reportId,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'reportId': reportId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Listen to new unread notifications for current user ───────────────────
  // Call once after login; shows local notification for each new record.

  static Stream<QuerySnapshot<Map<String, dynamic>>> userNotificationsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ── Convenience wrappers for report status changes ────────────────────────

  static Future<void> notifyReportStatus({
    required String userId,
    required String reportTitle,
    required String newStatus,
    required String reportId,
  }) async {
    String title;
    String body;

    switch (newStatus) {
      case 'Diproses':
        title = '⚙️ Laporan Sedang Diproses';
        body = 'Laporan "$reportTitle" kamu sedang ditangani oleh tim kami.';
        break;
      case 'Selesai':
        title = '✅ Laporan Selesai! +20 Poin Horas';
        body =
            'Laporan "$reportTitle" telah berhasil diselesaikan. Terima kasih atas kontribusimu!';
        break;
      case 'Dihapus':
        title = '🗑️ Laporan Dihapus';
        body =
            'Laporan "$reportTitle" dihapus oleh admin. Cek detail untuk alasan penghapusan.';
        break;
      default:
        return;
    }

    await writeNotification(
      userId: userId,
      title: title,
      body: body,
      type: 'report_status',
      reportId: reportId,
    );
  }
}
