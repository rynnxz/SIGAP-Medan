import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isEmailVerified;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isEmailVerified = true,
  });

  @override
  Widget build(BuildContext context) {
    const horizontalMargin = 20.0;
    const navbarHeight = 70.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: horizontalMargin),
      height: navbarHeight,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
            blurRadius: 28,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          _buildNavItem(
            context: context,
            icon: LucideIcons.map,
            label: 'Peta',
            index: 0,
            isActive: currentIndex == 0,
          ),
          _buildNavItem(
            context: context,
            icon: LucideIcons.footprints,
            label: 'Jejak Kesawan',
            index: 1,
            isActive: currentIndex == 1,
          ),
          // FAB DI TENGAH
          SizedBox(
            width: 70,
            child: Center(
              child: GestureDetector(
                onTap: () => onTap(-1),
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Opacity(
                      opacity: isEmailVerified ? 1.0 : 0.55,
                      child: Container(
                        width: 50,
                        height: 50,
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
                              color: const Color(0xFF10B981).withValues(alpha: 0.4),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.plus,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    if (!isEmailVerified)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF1F2937)
                                  : Colors.white,
                              width: 1.5,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              LucideIcons.lock,
                              size: 9,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          _buildNavItem(
            context: context,
            icon: LucideIcons.trophy,
            label: 'Point Horas',
            index: 2,
            isActive: currentIndex == 2,
          ),
          _buildNavItem(
            context: context,
            icon: LucideIcons.user,
            label: 'Profile',
            index: 3,
            isActive: currentIndex == 3,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Flexible(
      flex: 1,
      fit: FlexFit.tight,
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive 
                ? const Color(0xFF10B981)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: isActive 
                ? Colors.white
                : (isDark 
                    ? const Color(0xFF9CA3AF) 
                    : const Color(0xFF6B7280)),
            size: 24,
          ),
        ),
      ),
    );
  }
}
