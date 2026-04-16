import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../screens/report_form_screen.dart';
import 'verification_guard.dart';

void showReportCategorySheet(BuildContext context) {
  showFSheet(
    context: context,
    side: .btt,
    builder: (context) => const _ReportCategorySheet(),
  );
}

class MainReportButton extends StatelessWidget {
  const MainReportButton({super.key});

  void _open(BuildContext context) {
    showFSheet(
      context: context,
      side: .btt,
      builder: (context) => const _ReportCategorySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF10B981),
              Color(0xFF059669),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.6),
              blurRadius: 25,
              offset: const Offset(0, 8),
              spreadRadius: 3,
            ),
          ],
        ),
        child: const Icon(
          LucideIcons.plus,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }
}

class _ReportCategorySheet extends StatelessWidget {
  const _ReportCategorySheet();

  Future<void> _go(BuildContext context, String category) async {
    final verified = await VerificationGuard.require(context);
    if (!verified) return;
    if (!context.mounted) return;
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportFormScreen(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color:
                      (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB))
                          .withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              'Pilih Kategori Laporan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            _CategoryOptionCard(
              icon: LucideIcons.leaf,
              title: 'Lingkungan & Bencana',
              description: 'Sampah, banjir, pohon tumbang.',
              onTap: () => _go(context, 'Lingkungan & Bencana'),
            ),
            const SizedBox(height: 10),
            _CategoryOptionCard(
              icon: LucideIcons.car,
              title: 'Transportasi & Mobilitas',
              description: 'Lampu lalu lintas, rambu, kemacetan.',
              onTap: () => _go(context, 'Transportasi & Mobilitas'),
            ),
            const SizedBox(height: 10),
            _CategoryOptionCard(
              icon: LucideIcons.building2,
              title: 'Layanan Publik',
              description: 'Fasilitas rusak, vandalisme.',
              onTap: () => _go(context, 'Layanan Publik'),
            ),
            const SizedBox(height: 10),
            _CategoryOptionCard(
              icon: LucideIcons.shieldAlert,
              title: 'Ketertiban Sosial',
              description: 'Parkir liar, trotoar beralih fungsi.',
              onTap: () => _go(context, 'Ketertiban Sosial'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _CategoryOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0B1220) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF10B981),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color:
                      isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
