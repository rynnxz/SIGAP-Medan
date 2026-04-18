/**
 * Firebase Cloud Functions — SIGAP Medan
 *
 * Fungsi yang tersedia:
 *   1. onSosAlert          — SOS baru → push FCM ke semua admin
 *   2. onNotificationCreated — notifikasi baru di Firestore → push FCM ke user
 *
 * Deploy:
 *   cd functions
 *   npm install
 *   cd ..
 *   firebase deploy --only functions
 *
 * Prasyarat:
 *   - Firebase project sudah diinisialisasi (firebase init)
 *   - FCM token tersimpan di Firestore users/{uid}.fcmToken
 *     (otomatis disimpan oleh FcmTokenService saat login)
 */

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp }     = require('firebase-admin/app');
const { getFirestore }       = require('firebase-admin/firestore');
const { getMessaging }       = require('firebase-admin/messaging');

initializeApp();

exports.onSosAlert = onDocumentCreated(
  'sos_alerts/{alertId}',
  async (event) => {
    const data     = event.data.data();
    const alertId  = event.params.alertId;
    const db       = getFirestore();

    // Ambil semua FCM token admin yang aktif
    const adminsSnap = await db
      .collection('users')
      .where('accountType', '==', 'admin')
      .get();

    const tokens = [];
    adminsSnap.forEach((doc) => {
      const token = doc.data().fcmToken;
      if (token) tokens.push(token);
    });

    if (tokens.length === 0) {
      console.log('No admin FCM tokens found, skipping push.');
      return;
    }

    const lat = data.latitude  ? data.latitude.toFixed(6)  : '—';
    const lng = data.longitude ? data.longitude.toFixed(6) : '—';

    const message = {
      tokens,
      notification: {
        title: '🚨 SOS Darurat!',
        body:  `${data.userName} mengirim sinyal: ${data.category} (${lat}, ${lng})`,
      },
      data: {
        type:     'sos_alert',
        alertId,
        lat:      String(data.latitude  ?? 0),
        lng:      String(data.longitude ?? 0),
        category: data.category ?? '',
        userName: data.userName ?? '',
      },
      android: {
        priority: 'high',
        notification: {
          channelId:              'sos_alerts',
          priority:               'max',
          defaultSound:           true,
          defaultVibrateTimings:  true,
          color:                  '#EF4444',
        },
      },
      apns: {
        payload: {
          aps: {
            sound:            'default',
            badge:            1,
            contentAvailable: true,
          },
        },
      },
    };

    const result = await getMessaging().sendEachForMulticast(message);
    console.log(
      `SOS push sent: ${result.successCount} ok, ${result.failureCount} fail`
    );
  }
);

// ── Trigger 2: Notifikasi baru → FCM push ke user yang bersangkutan ──────────

exports.onNotificationCreated = onDocumentCreated(
  'notifications/{notifId}',
  async (event) => {
    const data   = event.data.data();
    const userId = data.userId;
    if (!userId) return;

    const db       = getFirestore();
    const userSnap = await db.collection('users').doc(userId).get();
    if (!userSnap.exists) return;

    const fcmToken = userSnap.data().fcmToken;
    if (!fcmToken) {
      console.log(`User ${userId} has no FCM token, skipping push.`);
      return;
    }

    const isSos = data.type === 'sos_alert';

    const message = {
      token: fcmToken,
      notification: {
        title: data.title  ?? 'SIGAP Medan',
        body:  data.body   ?? '',
      },
      data: {
        type:     data.type     ?? 'general',
        reportId: data.reportId ?? '',
      },
      android: {
        priority: 'high',
        notification: {
          channelId:             isSos ? 'sos_alerts' : 'sigap_medan',
          priority:              isSos ? 'max' : 'high',
          defaultSound:          true,
          defaultVibrateTimings: isSos,
          color:                 isSos ? '#EF4444' : '#10B981',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    try {
      await getMessaging().send(message);
      console.log(`Push sent to user ${userId} (type: ${data.type})`);
    } catch (err) {
      console.error(`Failed to send push to user ${userId}:`, err.message);
      // Hapus token invalid agar tidak retry terus
      if (err.code === 'messaging/registration-token-not-registered') {
        await db.collection('users').doc(userId).update({ fcmToken: null });
      }
    }
  }
);
