import 'package:cloud_firestore/cloud_firestore.dart';

/// Current app version — keep in sync with pubspec.yaml version field.
const String kAppVersion = '1.0.2';

enum AppGateStatus { loading, ok, needsUpdate, killed }

class AppConfig {
  final bool isActive;
  final String minVersion;
  final String killMessage;
  final String updateMessage;
  final String updateUrl;

  const AppConfig({
    required this.isActive,
    required this.minVersion,
    required this.killMessage,
    required this.updateMessage,
    required this.updateUrl,
  });

  factory AppConfig.fromMap(Map<String, dynamic> data) => AppConfig(
        isActive: data['is_active'] as bool? ?? true,
        minVersion: data['min_version'] as String? ?? '1.0.0',
        killMessage: data['kill_message'] as String? ??
            'Aplikasi sedang dalam pemeliharaan. Silakan coba lagi nanti.',
        updateMessage: data['update_message'] as String? ??
            'Tersedia versi terbaru. Harap perbarui aplikasi untuk melanjutkan.',
        updateUrl: data['update_url'] as String? ?? '',
      );

  AppGateStatus get gateStatus {
    if (!isActive) return AppGateStatus.killed;
    if (_compareSemVer(kAppVersion, minVersion) < 0) {
      return AppGateStatus.needsUpdate;
    }
    return AppGateStatus.ok;
  }
}

/// Returns negative if [a] < [b], 0 if equal, positive if [a] > [b].
int _compareSemVer(String a, String b) {
  final av = _parseVer(a);
  final bv = _parseVer(b);
  for (int i = 0; i < 3; i++) {
    final diff = av[i] - bv[i];
    if (diff != 0) return diff;
  }
  return 0;
}

List<int> _parseVer(String v) {
  final parts = v.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  while (parts.length < 3) parts.add(0);
  return parts;
}

class AppConfigService {
  static final _db = FirebaseFirestore.instance;
  static const _doc = 'main/main';

  static Stream<AppConfig> stream() {
    return _db.doc(_doc).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return AppConfig.fromMap({});
      }
      return AppConfig.fromMap(snap.data()!);
    });
  }
}
