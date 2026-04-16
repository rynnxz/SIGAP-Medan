import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPrefKey = 'isTutorialSeen';

Future<bool> isTutorialSeen() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kPrefKey) ?? false;
}

Future<void> markTutorialSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kPrefKey, true);
}

Future<void> showOnboardingIfNeeded(BuildContext context) async {
  final seen = await isTutorialSeen();
  if (seen) return;
  if (!context.mounted) return;
  await showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (_) => const _OnboardingDialog(),
  );
  await markTutorialSeen();
}

// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingDialog extends StatefulWidget {
  const _OnboardingDialog();

  @override
  State<_OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<_OnboardingDialog> {
  final PageController _pageCtrl = PageController();
  int _current = 0;

  static const _pages = [
    _OnboardingPage(
      icon: LucideIcons.clipboardList,
      iconColor: Color(0xFF10B981),
      title: 'Cara Melapor',
      body:
          'Ketuk tombol + di halaman Beranda, pilih kategori masalah, ambil foto, '
          'lalu tandai lokasi pada peta. Laporan kamu langsung diterima dan '
          'dipantau oleh tim SIGAP Medan secara real-time.',
      steps: [
        (LucideIcons.plusCircle, 'Ketuk tombol Laporkan'),
        (LucideIcons.camera, 'Foto & isi deskripsi'),
        (LucideIcons.mapPin, 'Konfirmasi lokasi'),
        (LucideIcons.send, 'Kirim laporan'),
      ],
    ),
    _OnboardingPage(
      icon: LucideIcons.star,
      iconColor: Color(0xFFF59E0B),
      title: 'Poin Horas',
      body:
          'Setiap aksi positif menghasilkan Poin Horas. Kumpulkan poin untuk '
          'naik level dan dapatkan lencana kehormatan sebagai warga aktif Kota Medan.',
      steps: [
        (LucideIcons.fileText, 'Lapor masalah → +50 XP'),
        (LucideIcons.messageSquare, 'Komentar → +5 XP'),
        (LucideIcons.thumbsUp, 'Upvote diterima → +10 XP'),
        (LucideIcons.checkCircle, 'Laporan selesai → +100 XP'),
      ],
    ),
    _OnboardingPage(
      icon: LucideIcons.mapPin,
      iconColor: Color(0xFF8B5CF6),
      title: 'Jejak Kesawan',
      body:
          'Jelajahi kawasan bersejarah Kesawan secara langsung. Check-in di '
          'setiap destinasi wisata untuk menyelesaikan quest dan menangkan poin eksklusif.',
      steps: [
        (LucideIcons.map, 'Buka tab Jejak Kesawan'),
        (LucideIcons.navigation, 'Pergi ke lokasi destinasi'),
        (LucideIcons.scanLine, 'Check-in via GPS'),
        (LucideIcons.award, 'Raih lencana eksklusif'),
      ],
    ),
  ];

  void _next() {
    if (_current < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _skip() => Navigator.of(context).pop();

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLast = _current == _pages.length - 1;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── PageView ───────────────────────────────────────────────────
            SizedBox(
              height: 420,
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (_, i) => _pages[i].build(context, isDark),
              ),
            ),

            // ── Dots ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final active = i == _current;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active
                          ? _pages[_current].iconColor
                          : (isDark
                              ? const Color(0xFF48484A)
                              : const Color(0xFFD1D1D6)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // ── Divider ────────────────────────────────────────────────────
            Divider(
              height: 1,
              color: isDark
                  ? const Color(0xFF38383A)
                  : const Color(0xFFE5E5EA),
            ),

            // ── Buttons ────────────────────────────────────────────────────
            IntrinsicHeight(
              child: Row(
                children: [
                  // Lewati
                  Expanded(
                    child: TextButton(
                      onPressed: _skip,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                          ),
                        ),
                      ),
                      child: Text(
                        'Lewati',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: isDark
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                  ),

                  VerticalDivider(
                    width: 1,
                    color: isDark
                        ? const Color(0xFF38383A)
                        : const Color(0xFFE5E5EA),
                  ),

                  // Lanjut / Mulai
                  Expanded(
                    child: TextButton(
                      onPressed: _next,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(24),
                          ),
                        ),
                      ),
                      child: Text(
                        isLast ? 'Mulai!' : 'Lanjut',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _pages[_current].iconColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingPage {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final List<(IconData, String)> steps;

  const _OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.steps,
  });

  Widget build(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),

          const SizedBox(height: 14),

          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1C1C1E),
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 8),

          // Body
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? const Color(0xFF8E8E93)
                  : const Color(0xFF6C6C70),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 14),

          // Steps
          ...steps.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(s.$1, size: 15, color: iconColor),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    s.$2,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : const Color(0xFF3A3A3C),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
