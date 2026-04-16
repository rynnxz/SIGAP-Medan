# SIGAP-Medan

Aplikasi pelaporan masalah kota dan informasi wisata Kota Medan berbasis Flutter + Firebase.

## Fitur Utama
- Laporan masalah kota (foto, lokasi, kategori)
- Admin panel: review, assign ke Dinas terkait
- Portal Dinas: tindak lanjut & upload bukti penyelesaian
- SOS darurat dengan notifikasi real-time ke admin
- Peta interaktif (OpenStreetMap)
- Forum komunitas
- Gamifikasi Poin Horas
- Destinasi wisata Medan

## Setup

### 1. Clone & Install
```bash
git clone https://github.com/rynnxz/SIGAP-Medan.git
cd SIGAP-Medan
flutter pub get
```

### 2. Firebase
- Buat project Firebase dan aktifkan Firestore, Auth, Storage
- Download `google-services.json` → taruh di `android/app/`
- Generate `firebase_options.dart` via FlutterFire CLI → taruh di `lib/`

### 3. Cloudinary Secrets
```bash
cp lib/config/secrets.example.dart lib/config/secrets.dart
```
Edit `lib/config/secrets.dart` dengan credentials Cloudinary kamu.

### 4. Run
```bash
flutter run
```

## Struktur Akun Firestore

| accountType | Akses |
|---|---|
| `user` | Masyarakat umum |
| `admin` | Admin panel |
| `dinas` | Portal Dinas (butuh field `dinasName`) |

## Tech Stack
Flutter · Firebase (Firestore, Auth) · Cloudinary · OpenStreetMap · Lucide Icons
