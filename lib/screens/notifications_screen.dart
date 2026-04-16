import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _markAllRead() async {
    if (_uid == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: _uid)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> _markRead(String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .update({'isRead': true});
  }

  Future<void> _deleteNotif(String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft,
              color: isDark ? Colors.white : const Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifikasi',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text(
              'Tandai Dibaca',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF10B981),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: const Color(0xFF10B981),
          unselectedLabelColor:
              isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          indicatorColor: const Color(0xFF10B981),
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Belum Dibaca'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _NotifList(
            uid: _uid,
            isDark: isDark,
            onlyUnread: false,
            onMarkRead: _markRead,
            onDelete: _deleteNotif,
          ),
          _NotifList(
            uid: _uid,
            isDark: isDark,
            onlyUnread: true,
            onMarkRead: _markRead,
            onDelete: _deleteNotif,
          ),
        ],
      ),
    );
  }
}

class _NotifList extends StatelessWidget {
  final String? uid;
  final bool isDark;
  final bool onlyUnread;
  final Future<void> Function(String) onMarkRead;
  final Future<void> Function(String) onDelete;

  const _NotifList({
    required this.uid,
    required this.isDark,
    required this.onlyUnread,
    required this.onMarkRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const Center(child: Text('Belum login'));
    }

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true);

    if (onlyUnread) {
      query = query.where('isRead', isEqualTo: false);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF10B981)),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.bellOff,
                    size: 48,
                    color: isDark
                        ? const Color(0xFF4B5563)
                        : const Color(0xFFD1D5DB)),
                const SizedBox(height: 16),
                Text(
                  onlyUnread
                      ? 'Semua notifikasi sudah dibaca'
                      : 'Belum ada notifikasi',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data();
            final isRead = data['isRead'] as bool? ?? true;
            final title = data['title'] as String? ?? '';
            final body = data['body'] as String? ?? '';
            final type = data['type'] as String? ?? '';
            final ts = data['createdAt'];
            final timeStr = ts is Timestamp
                ? _formatTs(ts.toDate())
                : '';

            return Dismissible(
              key: Key(doc.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(LucideIcons.trash2,
                    color: Colors.red, size: 20),
              ),
              onDismissed: (_) => onDelete(doc.id),
              child: GestureDetector(
                onTap: () => onMarkRead(doc.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isRead
                        ? (isDark
                            ? const Color(0xFF1F2937)
                            : Colors.white)
                        : (isDark
                            ? const Color(0xFF10B981).withValues(alpha: 0.08)
                            : const Color(0xFF10B981).withValues(alpha: 0.06)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isRead
                          ? (isDark
                              ? const Color(0xFF374151)
                              : const Color(0xFFE5E7EB))
                          : const Color(0xFF10B981).withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NotifIcon(type: type, isDark: isDark),
                      const SizedBox(width: 12),
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
                                      fontSize: 14,
                                      fontWeight: isRead
                                          ? FontWeight.w500
                                          : FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1F2937),
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              body,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: isDark
                                    ? const Color(0xFFD1D5DB)
                                    : const Color(0xFF4B5563),
                              ),
                            ),
                            if (timeStr.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? const Color(0xFF6B7280)
                                      : const Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTs(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _NotifIcon extends StatelessWidget {
  final String type;
  final bool isDark;

  const _NotifIcon({required this.type, required this.isDark});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (type) {
      case 'report_status':
        icon = LucideIcons.fileText;
        color = const Color(0xFF3B82F6);
        break;
      case 'streak':
        icon = LucideIcons.flame;
        color = const Color(0xFFEF4444);
        break;
      case 'achievement':
        icon = LucideIcons.award;
        color = const Color(0xFFF59E0B);
        break;
      default:
        icon = LucideIcons.bell;
        color = const Color(0xFF10B981);
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

// Separate settings page accessible from profile → Notifikasi
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _streakReminder = true;
  bool _reportUpdates = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft,
              color: isDark ? Colors.white : const Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pengaturan Notifikasi',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SettingsTile(
            isDark: isDark,
            icon: LucideIcons.flame,
            iconColor: const Color(0xFFEF4444),
            title: 'Reminder Streak Harian',
            subtitle: 'Pengingat pukul 20:00 untuk menjaga streak',
            value: _streakReminder,
            onChanged: (v) async {
              setState(() => _streakReminder = v);
              if (v) {
                await NotificationService.scheduleStreakReminder();
              } else {
                await NotificationService.cancelStreakReminder();
              }
            },
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            isDark: isDark,
            icon: LucideIcons.fileText,
            iconColor: const Color(0xFF3B82F6),
            title: 'Update Status Laporan',
            subtitle: 'Notifikasi saat laporan diproses atau selesai',
            value: _reportUpdates,
            onChanged: (v) => setState(() => _reportUpdates = v),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsTile({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
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
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }
}
