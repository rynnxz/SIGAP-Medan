import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'splash_screen.dart';
import 'login_screen.dart';
import 'location_permission_screen.dart';
import '../services/notification_service.dart';
import '../services/user_profile_service.dart';

class AuthWrapper extends StatefulWidget {
  final ThemeMode currentTheme;
  final Function(ThemeMode) onThemeChanged;

  const AuthWrapper({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showSplash = true;
  String? _lastHandledUid;

  @override
  void initState() {
    super.initState();
    NotificationService.init().then((_) => NotificationService.requestPermission());
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  Future<void> _onUserLoggedIn(String uid) async {
    if (_lastHandledUid == uid) return;
    _lastHandledUid = uid;
    final newStreak = await UserProfileService().updateLoginStreak();
    if (newStreak != null) {
      await NotificationService.scheduleStreakReminder();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onComplete: () {
          if (mounted) setState(() => _showSplash = false);
        },
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!authSnap.hasData) return const LoginScreen();

        final user = authSnap.data!;
        _onUserLoggedIn(user.uid);

        // ── Listen to Firestore user doc for ban / suspend status ──────────
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (userSnap.hasData && userSnap.data!.exists) {
              final data = userSnap.data!.data() as Map<String, dynamic>;

              // Banned
              if (data['isBanned'] == true) {
                return _BannedScreen(reason: data['banReason'] as String?);
              }

              // Suspended
              final suspendedUntil = data['suspendedUntil'] as Timestamp?;
              if (suspendedUntil != null &&
                  suspendedUntil.toDate().isAfter(DateTime.now())) {
                return _SuspendedScreen(until: suspendedUntil.toDate());
              }
            }

            return LocationPermissionScreen(
              onThemeChanged: widget.onThemeChanged,
            );
          },
        );
      },
    );
  }
}

// ── Shared sign-out helper ──────────────────────────────────────────────────

Future<void> _signOut() async {
  await GoogleSignIn().signOut();
  await FirebaseAuth.instance.signOut();
}

// ── Ban Screen ──────────────────────────────────────────────────────────────

class _BannedScreen extends StatelessWidget {
  final String? reason;
  const _BannedScreen({this.reason});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                        width: 1.5),
                  ),
                  child: const Icon(LucideIcons.ban,
                      size: 36, color: Color(0xFFEF4444)),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Akun Diblokir',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'BAN PERMANEN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFEF4444),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  reason != null && reason!.isNotEmpty
                      ? 'Alasan: $reason'
                      : 'Akunmu telah diblokir secara permanen karena melanggar ketentuan layanan SIGAP Medan.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: _signOut,
                  child: const Text(
                    'Keluar dari akun ini',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Suspend Screen ──────────────────────────────────────────────────────────

class _SuspendedScreen extends StatelessWidget {
  final DateTime until;
  const _SuspendedScreen({required this.until});

  @override
  Widget build(BuildContext context) {
    final formatted =
        DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(until);

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                        width: 1.5),
                  ),
                  child: const Icon(LucideIcons.clock,
                      size: 36, color: Color(0xFFF59E0B)),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Akun Disuspend',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'SUSPEND SEMENTARA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF59E0B),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Akunmu sedang disuspend karena melanggar ketentuan layanan. Kamu bisa mengakses kembali setelah:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color:
                            const Color(0xFFF59E0B).withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    formatted,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: _signOut,
                  child: const Text(
                    'Keluar dari akun ini',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
