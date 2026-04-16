import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/profile_header_card.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import 'about_developer_screen.dart';
import 'about_app_screen.dart';
import 'faq_screen.dart';
import 'user_settings_screen.dart';
import 'notifications_screen.dart';
import 'report_history_screen.dart';
import 'admin/admin_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ThemeMode currentTheme;
  final Function(ThemeMode) onThemeChanged;

  const ProfileScreen({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserProfileService _profileService = UserProfileService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late ThemeMode _localTheme;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _localTheme = widget.currentTheme;
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _appVersion = info.version);
    });
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentTheme != widget.currentTheme) {
      _localTheme = widget.currentTheme;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      body: SafeArea(
        child: StreamBuilder<UserProfile?>(
          stream: _profileService.getUserProfile(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF10B981),
                ),
              );
            }

            final userProfile = snapshot.data;
            final user = _auth.currentUser;

            // If no profile exists, create one
            if (userProfile == null && user != null) {
              _profileService.createOrUpdateProfile(
                uid: user.uid,
                name: user.displayName ?? 'User',
                email: user.email ?? '',
                photoUrl: user.photoURL,
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Profil Saya',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // User Info Section - Gamified Card with real data
                  ProfileHeaderCard(
                    name: userProfile?.name ?? user?.displayName ?? 'User',
                    email: userProfile?.email ?? user?.email ?? '',
                    initials: _getInitials(userProfile?.name ?? user?.displayName ?? 'U'),
                    photoUrl: userProfile?.photoUrl ?? user?.photoURL,
                    badge: userProfile?.level ?? 'Pemula',
                  ),

                  const SizedBox(height: 24),

                  // ── Reward & XP Section ──────────────────────────────────
                  Text(
                    'Reward & Perkembangan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // XP Card
                      Expanded(
                        child: _buildRewardCard(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          icon: LucideIcons.zap,
                          value: '${userProfile?.currentXP ?? 0}',
                          label: 'Current XP',
                          sublabel:
                              'Level ${userProfile?.level ?? "Pemula"}',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Poin Horas Card
                      Expanded(
                        child: _buildRewardCard(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          icon: LucideIcons.coins,
                          value: '${userProfile?.poinHoras ?? 0}',
                          label: 'Poin Horas',
                          sublabel: 'Level ${userProfile?.level ?? "Pemula"}',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // XP Progress bar card
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1F2937)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(isDark ? 0.3 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (userProfile?.currentXP ?? 0) >= 2000
                                      ? 'Penjaga Kota (Level Maks)'
                                      : 'Menuju ${_nextLevel(userProfile?.level ?? "Pemula")}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFF9CA3AF)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                                Text(
                                  userProfile?.level ?? 'Pemula',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${userProfile?.currentXP ?? 0} / ${userProfile?.maxXP ?? 200} XP',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: userProfile?.progressPercentage ?? 0.0,
                            minHeight: 10,
                            backgroundColor: isDark
                                ? const Color(0xFF374151)
                                : const Color(0xFFE5E7EB),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF10B981)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(LucideIcons.mapPin,
                                    size: 13,
                                    color: Color(0xFF10B981)),
                                const SizedBox(width: 4),
                                Text(
                                  '${userProfile?.totalCheckIns ?? 0} Check-in',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? const Color(0xFF9CA3AF)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(LucideIcons.flame,
                                    size: 13,
                                    color: Color(0xFFEF4444)),
                                const SizedBox(width: 4),
                                Text(
                                  '${userProfile?.streakDays ?? 0} Hari Streak',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? const Color(0xFF9CA3AF)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Admin Panel (only for admin users)
                  if (userProfile?.accountType == 'admin') ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminDashboardScreen(),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                LucideIcons.shield,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Admin Panel',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Kelola aplikasi SIGAP Medan',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              LucideIcons.chevronRight,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // ── Aktivitas Section ────────────────────────────────
                  Text(
                    'Aktivitas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F2937) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                              alpha: isDark ? 0.3 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _buildSettingItem(
                      icon: LucideIcons.trash2,
                      title: 'Log Laporan Dihapus',
                      subtitle: 'Riwayat laporan yang dihapus admin',
                      isDark: isDark,
                      iconColor: const Color(0xFFEF4444),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReportHistoryScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Theme Settings Section
                  Text(
                    'Pengaturan Tampilan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark 
                          ? const Color(0xFF9CA3AF) 
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Theme Toggle Segmented Control
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F2937) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildThemeOption(
                          icon: LucideIcons.sun,
                          label: 'Light',
                          mode: ThemeMode.light,
                          isActive: _localTheme == ThemeMode.light,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 6),
                        _buildThemeOption(
                          icon: LucideIcons.moon,
                          label: 'Dark',
                          mode: ThemeMode.dark,
                          isActive: _localTheme == ThemeMode.dark,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 6),
                        _buildThemeOption(
                          icon: LucideIcons.monitor,
                          label: 'System',
                          mode: ThemeMode.system,
                          isActive: _localTheme == ThemeMode.system,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Settings Section
                  Text(
                    'Pengaturan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark 
                          ? const Color(0xFF9CA3AF) 
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F2937) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSettingItem(
                          icon: LucideIcons.settings,
                          title: 'Pengaturan Akun',
                          subtitle: 'Edit profil, ubah password',
                          isDark: isDark,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UserSettingsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(isDark),
                        _buildSettingItem(
                          icon: LucideIcons.bell,
                          title: 'Notifikasi',
                          subtitle: 'Kelola notifikasi aplikasi',
                          isDark: isDark,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(isDark),
                        _buildSettingItem(
                          icon: LucideIcons.globe,
                          title: 'Bahasa',
                          subtitle: 'Bahasa Indonesia',
                          isDark: isDark,
                          onTap: () => _showLanguageDialog(context, isDark),
                        ),
                        _buildDivider(isDark),
                        _buildSettingItem(
                          icon: LucideIcons.shieldCheck,
                          title: 'Privasi & Keamanan',
                          subtitle: 'Password dan keamanan akun',
                          isDark: isDark,
                          onTap: () => _showSecurityDialog(context, isDark),
                        ),
                        _buildDivider(isDark),
                        _buildSettingItem(
                          icon: LucideIcons.helpCircle,
                          title: 'FAQ',
                          subtitle: 'Pertanyaan yang sering diajukan',
                          isDark: isDark,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FaqScreen(),
                            ),
                          ),
                        ),
                        _buildDivider(isDark),
                        _buildSettingItem(
                          icon: LucideIcons.info,
                          title: 'Tentang Aplikasi',
                          subtitle: 'Versi ${_appVersion.isEmpty ? '...' : _appVersion} • SIGAP Medan',
                          isDark: isDark,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AboutAppScreen(),
                            ),
                          ),
                        ),
                        _buildDivider(isDark),
                        _buildSettingItem(
                          icon: LucideIcons.code,
                          title: 'Tentang Developer',
                          subtitle: 'Kenali pembuat SIGAP Medan',
                          isDark: isDark,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AboutDeveloperScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(isDark),
                        _buildSettingItem(
                          icon: LucideIcons.logOut,
                          title: 'Keluar',
                          subtitle: 'Logout dari aplikasi',
                          isDark: isDark,
                          isDestructive: true,
                          onTap: () => _showLogoutDialog(context),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Stats Section with real data
                  Text( 
                    'Statistik',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark 
                          ? const Color(0xFF9CA3AF) 
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: LucideIcons.fileText,
                          label: 'Laporan',
                          value: '${userProfile?.totalReports ?? 0}',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: LucideIcons.mapPin,
                          label: 'Check-ins',
                          value: '${userProfile?.totalCheckIns ?? 0}',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: LucideIcons.thumbsUp,
                          label: 'Upvotes',
                          value: '${userProfile?.totalUpvotes ?? 0}',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: LucideIcons.messageCircle,
                          label: 'Komentar',
                          value: '${userProfile?.totalComments ?? 0}',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: LucideIcons.checkCircle,
                          label: 'Terselesaikan',
                          value: '${userProfile?.reportsResolved ?? 0}',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: LucideIcons.star,
                          label: 'Reputasi',
                          value: '${userProfile?.reputation ?? 0}',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: LucideIcons.users,
                          label: 'Followers',
                          value: '${userProfile?.followers.length ?? 0}',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: LucideIcons.userPlus,
                          label: 'Following',
                          value: '${userProfile?.following.length ?? 0}',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _nextLevel(String current) {
    switch (current) {
      case 'Pemula':       return 'Penjelajah';
      case 'Penjelajah':   return 'Relawan';
      case 'Relawan':      return 'Detektif Kota';
      case 'Detektif Kota': return 'Penjaga Kota';
      default:             return 'Penjaga Kota';
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  void _showLanguageDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Pilih Bahasa',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _langOption(ctx, isDark, '🇮🇩', 'Bahasa Indonesia', true),
            const SizedBox(height: 8),
            _langOption(ctx, isDark, '🇬🇧', 'English', false),
          ],
        ),
      ),
    );
  }

  Widget _langOption(BuildContext ctx, bool isDark, String flag, String name, bool selected) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.pop(ctx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF10B981).withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? const Color(0xFF10B981)
                      : (isDark ? Colors.white : const Color(0xFF1F2937)),
                ),
              ),
            ),
            if (selected)
              const Icon(LucideIcons.check, size: 18, color: Color(0xFF10B981)),
          ],
        ),
      ),
    );
  }

  void _showSecurityDialog(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Privasi & Keamanan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            _securityTile(
              ctx,
              isDark,
              LucideIcons.lock,
              'Ganti Password',
              'Perbarui password akun kamu',
              () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserSettingsScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            _securityTile(
              ctx,
              isDark,
              LucideIcons.fingerprint,
              'Autentikasi Biometrik',
              'Gunakan sidik jari untuk login',
              () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 10),
            _securityTile(
              ctx,
              isDark,
              LucideIcons.trash2,
              'Hapus Akun',
              'Hapus akun dan semua data kamu',
              () => Navigator.pop(ctx),
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _securityTile(
    BuildContext ctx,
    bool isDark,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final color = isDestructive ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16,
                color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required IconData icon,
    required String label,
    required ThemeMode mode,
    required bool isActive,
    required bool isDark,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _localTheme = mode);
          widget.onThemeChanged(mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [
                      Color(0xFF10B981),
                      Color(0xFF059669),
                    ],
                  )
                : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isActive
                    ? Colors.white
                    : isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? Colors.white
                      : isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardCard({
    required LinearGradient gradient,
    required IconData icon,
    required String value,
    required String label,
    required String sublabel,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark 
                  ? const Color(0xFF9CA3AF) 
                  : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
    bool isDestructive = false,
    Color? iconColor,
  }) {
    final resolvedIconColor = isDestructive
        ? Colors.red
        : (iconColor ?? const Color(0xFF10B981));
    final titleColor = isDestructive
        ? Colors.red
        : (isDark ? Colors.white : const Color(0xFF1F2937));
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: resolvedIconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: resolvedIconColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: isDark 
                  ? const Color(0xFF6B7280) 
                  : const Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark 
            ? const Color(0xFF374151) 
            : const Color(0xFFE5E7EB),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                // Navigate to login screen and remove all previous routes
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
