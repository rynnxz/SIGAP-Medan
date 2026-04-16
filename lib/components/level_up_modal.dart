import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LevelUpModal extends StatefulWidget {
  final String newLevel;
  const LevelUpModal({super.key, required this.newLevel});

  static Future<void> show(BuildContext context, String newLevel) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LevelUpModal(newLevel: newLevel),
    );
  }

  @override
  State<LevelUpModal> createState() => _LevelUpModalState();
}

class _LevelUpModalState extends State<LevelUpModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  static const _levelColors = {
    'Penjelajah':   Color(0xFF3B82F6),
    'Relawan':      Color(0xFF10B981),
    'Detektif Kota': Color(0xFF8B5CF6),
    'Penjaga Kota': Color(0xFFF59E0B),
  };

  static const _levelIcons = {
    'Penjelajah':   LucideIcons.compass,
    'Relawan':      LucideIcons.heart,
    'Detektif Kota': LucideIcons.search,
    'Penjaga Kota': LucideIcons.crown,
  };

  static const _levelDesc = {
    'Penjelajah':   'Kamu mulai menjelajahi kota dengan aktif!',
    'Relawan':      'Kontribusimu sudah terasa di kota!',
    'Detektif Kota': 'Kamu jeli mendeteksi masalah di sekitarmu!',
    'Penjaga Kota': 'Kamu adalah pahlawan sejati kota Medan!',
  };

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color  = _levelColors[widget.newLevel] ?? const Color(0xFF10B981);
    final icon   = _levelIcons[widget.newLevel]  ?? LucideIcons.star;
    final desc   = _levelDesc[widget.newLevel]   ?? 'Level baru terbuka!';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge glow
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.4), width: 2),
                  ),
                  child: Icon(icon, size: 48, color: color),
                ),
                const SizedBox(height: 8),

                // Level up label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    'LEVEL UP!',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // New level name
                Text(
                  widget.newLevel,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),

                // Description
                Text(
                  desc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),

                // CTA button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Keren! 🎉',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
