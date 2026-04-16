import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

/// Service untuk verifikasi lokasi dan deteksi fake GPS
class LocationVerificationService {
  static const double CHECK_IN_RADIUS = 50.0; // meter
  static const int MIN_ACCURACY = 30; // meter
  static const int VERIFICATION_SAMPLES = 3; // jumlah sample lokasi
  static const Duration SAMPLE_INTERVAL = Duration(seconds: 2);
  
  /// Check apakah user berada di radius destinasi
  static Future<LocationCheckResult> verifyLocation(
    LatLng targetLocation,
  ) async {
    try {
      // 1. Cek permission dan service
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationCheckResult(
          success: false,
          message: 'GPS tidak aktif. Mohon aktifkan GPS Anda.',
          suspiciousActivity: false,
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationCheckResult(
            success: false,
            message: 'Izin lokasi ditolak.',
            suspiciousActivity: false,
          );
        }
      }

      // 2. Ambil multiple samples untuk deteksi fake GPS
      final samples = await _collectLocationSamples();
      
      if (samples.isEmpty) {
        return LocationCheckResult(
          success: false,
          message: 'Gagal mendapatkan lokasi. Coba lagi.',
          suspiciousActivity: false,
        );
      }

      // 3. Analisis samples untuk deteksi anomali
      final analysis = _analyzeSamples(samples);
      
      if (analysis.isSuspicious) {
        return LocationCheckResult(
          success: false,
          message: 'Terdeteksi aktivitas mencurigakan. Pastikan GPS asli dan tidak menggunakan fake GPS.',
          suspiciousActivity: true,
          suspiciousReasons: analysis.reasons,
        );
      }

      // 4. Gunakan sample terbaik untuk verifikasi jarak
      final bestSample = _getBestSample(samples);
      final distance = _calculateDistance(
        bestSample.latitude,
        bestSample.longitude,
        targetLocation.latitude,
        targetLocation.longitude,
      );

      if (distance <= CHECK_IN_RADIUS) {
        return LocationCheckResult(
          success: true,
          message: 'Check-in berhasil! Anda berada di lokasi yang tepat.',
          distance: distance,
          accuracy: bestSample.accuracy,
          suspiciousActivity: false,
        );
      } else {
        return LocationCheckResult(
          success: false,
          message: 'Anda terlalu jauh dari lokasi. Jarak: ${distance.toStringAsFixed(0)}m (maks: ${CHECK_IN_RADIUS.toStringAsFixed(0)}m)',
          distance: distance,
          accuracy: bestSample.accuracy,
          suspiciousActivity: false,
        );
      }
    } catch (e) {
      return LocationCheckResult(
        success: false,
        message: 'Error: ${e.toString()}',
        suspiciousActivity: false,
      );
    }
  }

  /// Kumpulkan multiple location samples
  static Future<List<Position>> _collectLocationSamples() async {
    final samples = <Position>[];
    
    for (int i = 0; i < VERIFICATION_SAMPLES; i++) {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
          ),
        );
        
        // Filter berdasarkan accuracy
        if (position.accuracy <= MIN_ACCURACY) {
          samples.add(position);
        }
        
        // Delay sebelum sample berikutnya
        if (i < VERIFICATION_SAMPLES - 1) {
          await Future.delayed(SAMPLE_INTERVAL);
        }
      } catch (e) {
        // Skip sample yang error
        continue;
      }
    }
    
    return samples;
  }

  /// Analisis samples untuk deteksi fake GPS
  static SampleAnalysis _analyzeSamples(List<Position> samples) {
    final reasons = <String>[];
    bool isSuspicious = false;

    // 1. Cek isMocked — Android mock location API (paling reliable, tidak false positive)
    //    Mendeteksi app fake GPS seperti Fake GPS Go, Mock Location, dll.
    final mockedCount = samples.where((s) => s.isMocked).length;
    if (mockedCount > 0) {
      
      isSuspicious = true;
      reasons.add('Mock location aktif di perangkat');
    }

    if (samples.length < 2) {
      return SampleAnalysis(isSuspicious: isSuspicious, reasons: reasons);
    }

    // 2. Cek teleportasi (pindah > 100m dalam ≤ 2 detik = ~180 km/jam)
    //    Aman untuk user diam karena tidak mensyaratkan koordinat berubah.
    for (int i = 1; i < samples.length; i++) {
      final distance = _calculateDistance(
        samples[i - 1].latitude,
        samples[i - 1].longitude,
        samples[i].latitude,
        samples[i].longitude,
      );
      final timeDiff = samples[i].timestamp
          .difference(samples[i - 1].timestamp)
          .inSeconds
          .abs();
      if (distance > 100 && timeDiff <= 2) {
        isSuspicious = true;
        reasons.add('Pergerakan tidak natural terdeteksi');
        break;
      }
    }

    // 3. Cek altitude tidak wajar (Medan ~25m dpl, batas longgar -100 s/d 2000m)
    final altitudes = samples.map((s) => s.altitude).toList();
    if (altitudes.any((a) => a != 0)) {
      final avg = altitudes.reduce((a, b) => a + b) / altitudes.length;
      if (avg < -100 || avg > 2000) {
        isSuspicious = true;
        reasons.add('Ketinggian tidak wajar');
      }
    }

    // DIHAPUS: cek "accuracy terlalu sempurna" — HP modern bisa genuinely < 5m
    // DIHAPUS: cek "koordinat identik" — user berdiri diam pasti koordinat sama

    return SampleAnalysis(
      isSuspicious: isSuspicious,
      reasons: reasons,
    );
  }

  /// Pilih sample dengan accuracy terbaik
  static Position _getBestSample(List<Position> samples) {
    return samples.reduce((a, b) => a.accuracy < b.accuracy ? a : b);
  }

  /// Hitung jarak antara dua koordinat (Haversine formula)
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const Distance distance = Distance();
    return distance.as(
      LengthUnit.Meter,
      LatLng(lat1, lon1),
      LatLng(lat2, lon2),
    );
  }

  /// Stream untuk real-time location tracking
  static Stream<Position> trackLocation() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update setiap 5 meter
      ),
    );
  }
}

/// Result dari location check
class LocationCheckResult {
  final bool success;
  final String message;
  final double? distance;
  final double? accuracy;
  final bool suspiciousActivity;
  final List<String>? suspiciousReasons;

  LocationCheckResult({
    required this.success,
    required this.message,
    this.distance,
    this.accuracy,
    required this.suspiciousActivity,
    this.suspiciousReasons,
  });
}

/// Analisis dari location samples
class SampleAnalysis {
  final bool isSuspicious;
  final List<String> reasons;

  SampleAnalysis({
    required this.isSuspicious,
    required this.reasons,
  });
}
