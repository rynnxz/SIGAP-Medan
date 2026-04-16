/**
 * Firebase Cloud Functions — SOS Alert → FCM Push ke semua admin
 *
 * Deploy:
 *   cd functions && npm install && cd ..
 *   firebase deploy --only functions
 *
 * Prasyarat:
 *   1. firebase init functions (pilih JavaScript)
 *   2. flutter: tambah firebase_messaging ke pubspec.yaml
 *   3. Simpan FCM token admin ke Firestore users/{uid}.fcmToken
 *      (lihat lib/services/fcm_token_service.dart)
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
