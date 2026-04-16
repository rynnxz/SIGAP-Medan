import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/auth_service.dart';

class VerificationGuard {
  VerificationGuard._();

  /// Returns `true` if the current user's email is verified (Google users always pass).
  /// Shows a dialog and returns `false` if not verified.
  static Future<bool> require(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    // Not logged in at all
    if (user == null) {
      _showDialog(context, _unverifiedContent(context, null));
      return false;
    }

    // Already verified (all Google users land here)
    if (user.emailVerified) return true;

    // Unverified — show blocking dialog
    _showDialog(context, _unverifiedContent(context, user));
    return false;
  }

  static void _showDialog(BuildContext context, Widget content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: content,
        ),
      ),
    );
  }

  static Widget _unverifiedContent(BuildContext context, User? user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor  = isDark ? Colors.white : const Color(0xFF1F2937);
    final mutedColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final isAnonymous = user == null || user.isAnonymous;

    return StatefulBuilder(
      builder: (ctx, setState) {
        bool sending = false;
        bool sent    = false;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.shieldAlert, size: 28, color: Color(0xFFF59E0B)),
            ),
            const SizedBox(height: 16),
            Text(
              'Verifikasi Akun Diperlukan',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textColor),
            ),
            const SizedBox(height: 10),
            Text(
              isAnonymous
                  ? 'Fitur ini hanya tersedia untuk pengguna yang sudah login dengan akun Google. Silakan keluar dan masuk kembali menggunakan akun Google kamu.'
                  : 'Email kamu belum diverifikasi. Cek inbox (atau folder spam) untuk menemukan email verifikasi dari kami.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: mutedColor, height: 1.5),
            ),
            const SizedBox(height: 20),
            if (!isAnonymous) ...[
              StatefulBuilder(
                builder: (ctx2, setState2) => Column(
                  children: [
                    if (sent)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.checkCircle,
                                size: 16, color: Color(0xFF10B981)),
                            const SizedBox(width: 6),
                            Text('Email terkirim! Cek inbox kamu.',
                                style: TextStyle(
                                    fontSize: 13, color: const Color(0xFF10B981))),
                          ],
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: sending || sent
                            ? null
                            : () async {
                                setState2(() => sending = true);
                                try {
                                  await AuthService().sendEmailVerification();
                                  setState2(() {
                                    sending = false;
                                    sent    = true;
                                  });
                                } catch (_) {
                                  setState2(() => sending = false);
                                }
                              },
                        icon: sending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(LucideIcons.mail, size: 16, color: Colors.white),
                        label: Text(
                          sent ? 'Email Terkirim' : 'Kirim Ulang Email Verifikasi',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Tutup', style: TextStyle(color: mutedColor)),
            ),
          ],
        );
      },
    );
  }
}
