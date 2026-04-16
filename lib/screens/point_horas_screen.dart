import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PointHorasScreen extends StatelessWidget {
  const PointHorasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Point Horas',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kumpulkan poin dari setiap kontribusi Anda',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark 
                      ? const Color(0xFF9CA3AF) 
                      : const Color(0xFF6B7280),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Point Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      LucideIcons.trophy,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Total Point Anda',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1,250',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Peringkat #42 di Medan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Cara Mendapat Point
              Text(
                'Cara Mendapat Point',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
              
              const SizedBox(height: 16),
              
              _buildPointItem(
                context: context,
                icon: LucideIcons.alertTriangle,
                title: 'Lapor Masalah',
                points: '+50 poin',
                description: 'Laporkan masalah infrastruktur di sekitar Anda',
              ),
              
              _buildPointItem(
                context: context,
                icon: LucideIcons.thumbsUp,
                title: 'Upvote Laporan',
                points: '+5 poin',
                description: 'Dukung laporan yang relevan dengan Anda',
              ),
              
              _buildPointItem(
                context: context,
                icon: LucideIcons.checkCircle,
                title: 'Laporan Terverifikasi',
                points: '+100 poin',
                description: 'Bonus ketika laporan Anda diverifikasi petugas',
              ),
              
              _buildPointItem(
                context: context,
                icon: LucideIcons.building2,
                title: 'Kunjungi Jejak Kesawan',
                points: '+10 poin',
                description: 'Check-in di lokasi bersejarah Kesawan',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String points,
    required String description,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark 
            ? Border.all(
                color: const Color(0xFF374151),
                width: 1,
              )
            : null,
        boxShadow: isDark 
            ? null 
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF10B981),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark 
                              ? Colors.white 
                              : const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    Text(
                      points,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark 
                        ? const Color(0xFF9CA3AF) 
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
