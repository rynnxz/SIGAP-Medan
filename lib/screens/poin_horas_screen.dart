import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/poin_horas_service.dart';

class PoinHorasScreen extends StatefulWidget {
  const PoinHorasScreen({super.key});

  @override
  State<PoinHorasScreen> createState() => _PoinHorasScreenState();
}

class _PoinHorasScreenState extends State<PoinHorasScreen> {
  int _selectedTabIndex = 0;
  final _auth = FirebaseAuth.instance;

  Future<void> _showRedeemConfirmation(String itemName, int cost, int currentPoin) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final bgColor = isDark ? const Color(0xFF111827) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF111827);
        final mutedColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.gift,
                    size: 26,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Konfirmasi Penukaran',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Apakah kamu yakin ingin menukarkan $cost Poin Horas untuk mendapatkan $itemName?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: mutedColor,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: FButton(
                        variant: FButtonVariant.outline,
                        mainAxisSize: MainAxisSize.max,
                        onPress: () {
                          Navigator.pop(dialogContext);
                        },
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FButton(
                        mainAxisSize: MainAxisSize.max,
                        onPress: () async {
                          if (currentPoin >= cost) {
                            Navigator.pop(dialogContext);
                            final uid = _auth.currentUser?.uid;
                            if (uid != null) {
                              await PoinHorasService.award(
                                userId: uid,
                                amount: -cost,
                                type: 'penukaran',
                                description: 'Tukar: $itemName',
                              );
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Berhasil menukarkan $itemName!'),
                                  backgroundColor: const Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          } else {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Maaf, Poin Horas kamu belum mencukupi.',
                                ),
                                backgroundColor: const Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text('Ya, Tukar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      body: SafeArea(
        child: uid == null
            ? const Center(child: Text('Belum login'))
            : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .snapshots(),
                builder: (context, snap) {
                  final data = snap.data?.data() as Map<String, dynamic>?;
                  final poin = (data?['poinHoras'] as int?) ?? 0;
                  final level = (data?['level'] as String?) ?? 'Pemula';

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PointsHeaderCard(
                          isDark: isDark,
                          currentPoin: poin,
                          level: level,
                        ),
                        const SizedBox(height: 16),
                        _SegmentedTabs(
                          isDark: isDark,
                          selectedIndex: _selectedTabIndex,
                          onSelect: (index) =>
                              setState(() => _selectedTabIndex = index),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: IndexedStack(
                            index: _selectedTabIndex,
                            children: [
                              _RedeemTab(
                                onRedeem: (name, cost) =>
                                    _showRedeemConfirmation(name, cost, poin),
                              ),
                              _LeaderboardTab(currentUserId: uid),
                              _HistoryTab(userId: uid),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _PointsHeaderCard extends StatelessWidget {
  final bool isDark;
  final int currentPoin;
  final String level;
  const _PointsHeaderCard({
    required this.isDark,
    required this.currentPoin,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Poin Horas',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                LucideIcons.coins,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                '$currentPoin',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.shieldCheck, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Level: $level',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final bool isDark;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _SegmentedTabs({
    required this.isDark,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);
    final textMuted = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: isDark ? 0.9 : 1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _SegmentedTabItem(
            label: 'Katalog',
            isActive: selectedIndex == 0,
            isDark: isDark,
            mutedColor: textMuted,
            onTap: () => onSelect(0),
          ),
          _SegmentedTabItem(
            label: 'Peringkat',
            isActive: selectedIndex == 1,
            isDark: isDark,
            mutedColor: textMuted,
            onTap: () => onSelect(1),
          ),
          _SegmentedTabItem(
            label: 'Riwayat',
            isActive: selectedIndex == 2,
            isDark: isDark,
            mutedColor: textMuted,
            onTap: () => onSelect(2),
          ),
        ],
      ),
    );
  }
}

class _SegmentedTabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isDark;
  final Color mutedColor;
  final VoidCallback onTap;

  const _SegmentedTabItem({
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.mutedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = isDark ? const Color(0xFF111827) : Colors.white;
    final activeText = isDark ? Colors.white : const Color(0xFF111827);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isActive ? activeText : mutedColor,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RedeemTab extends StatelessWidget {
  final void Function(String itemName, int cost) onRedeem;

  const _RedeemTab({required this.onRedeem});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = const [
      (title: 'Voucher Parkir E-Parking (1 Minggu)', points: 150, note: null),
      (title: 'Diskon GrabBike / GoRide 20%',        points: 200, note: null),
      (title: 'Kuota Internet 1 GB',                 points: 250, note: null),
      (title: 'Tiket Masuk Wisata Medan',             points: 300, note: null),
      (title: 'Saldo e-Wallet Rp 10.000',             points: 300, note: 'Syarat: Streak 7 Hari'),
      (title: 'Voucher Kuliner Medan Rp 25.000',      points: 400, note: null),
      (title: 'Merchandise MedanHub (Topi/Stiker)',   points: 500, note: null),
      (title: 'Saldo e-Wallet Rp 25.000',             points: 750, note: 'Syarat: Level Detektif+'),
      (title: 'Diskon Parkir 1 Bulan',                points: 800, note: 'Syarat: Level Penjaga+'),
    ];

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 110),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final item = items[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
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
                child: const Icon(
                  LucideIcons.gift,
                  color: Color(0xFF10B981),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(LucideIcons.coins, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Text(
                          '${item.points} Poin',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFD1FAE5) : const Color(0xFF047857),
                          ),
                        ),
                        if (item.note != null) ...[
                          const SizedBox(width: 10),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0B1220) : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                item.note!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FButton(
                mainAxisSize: MainAxisSize.min,
                onPress: () => onRedeem(item.title, item.points),
                child: const Text('Tukar'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  final String currentUserId;
  const _LeaderboardTab({required this.currentUserId});

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('poinHoras', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)));
        }
        if (snap.hasError) {
          return Center(
              child: Text('Error: ${snap.error}',
                  style: const TextStyle(color: Color(0xFFEF4444))));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.trophy,
                    size: 48,
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFD1D5DB)),
                const SizedBox(height: 12),
                Text('Belum ada data peringkat',
                    style: TextStyle(
                        color: isDark
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF9CA3AF))),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 110),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final uid = docs[index].id;
            final name = (data['name'] as String?) ?? 'Anonim';
            final poin = (data['poinHoras'] as int?) ?? 0;
            final isYou = uid == currentUserId;
            final rank = index + 1;

            final bg = isYou
                ? (isDark
                    ? const Color(0xFF0B1220).withValues(alpha: 0.9)
                    : const Color(0xFF10B981).withValues(alpha: 0.07))
                : (isDark ? const Color(0xFF1F2937) : Colors.white);
            final border = isYou
                ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.35 : 0.25)
                : (isDark
                    ? const Color(0xFF374151)
                    : const Color(0xFFE5E7EB));

            return Padding(
              padding:
                  EdgeInsets.only(bottom: index == docs.length - 1 ? 0 : 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: isDark ? 0.22 : 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: rank <= 3
                          ? Icon(
                              LucideIcons.crown,
                              size: 18,
                              color: rank == 1
                                  ? const Color(0xFFF59E0B)
                                  : rank == 2
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFFCD7F32),
                            )
                          : Text(
                              '$rank',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF111827),
                              ),
                            ),
                    ),
                    FAvatar.raw(
                      size: 34,
                      child: Text(
                        _initials(name),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF111827),
                              ),
                            ),
                          ),
                          if (isYou) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'Kamu',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$poin',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? const Color(0xFFD1FAE5)
                                : const Color(0xFF047857),
                          ),
                        ),
                        const Text(
                          'Poin Horas',
                          style: TextStyle(
                              fontSize: 10, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final String userId;
  const _HistoryTab({required this.userId});

  String _formatTs(dynamic ts) {
    if (ts == null) return '-';
    final dt = ts is Timestamp ? ts.toDate() : (ts as DateTime);
    final d = dt.day.toString().padLeft(2, '0');
    final mo = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ][dt.month - 1];
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$d $mo ${dt.year} • $h:$mi';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('poin_transactions')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)));
        }
        if (snap.hasError) {
          return Center(
              child: Text('Error: ${snap.error}',
                  style: const TextStyle(color: Color(0xFFEF4444))));
        }

        final docs = (snap.data?.docs ?? []).toList()
          ..sort((a, b) {
            final aTs = (a.data() as Map)['createdAt'] as Timestamp?;
            final bTs = (b.data() as Map)['createdAt'] as Timestamp?;
            if (aTs == null && bTs == null) return 0;
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            return bTs.compareTo(aTs);
          });

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.receipt,
                    size: 48,
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFD1D5DB)),
                const SizedBox(height: 12),
                Text('Belum ada transaksi',
                    style: TextStyle(
                        color: isDark
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF9CA3AF))),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 110),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final amount = (data['amount'] as int?) ?? 0;
            final isIn = amount > 0;
            final description = (data['description'] as String?) ?? '';
            final ts = data['createdAt'];
            final icon =
                isIn ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight;
            final iconColor =
                isIn ? const Color(0xFF10B981) : const Color(0xFFEF4444);
            final pointsColor =
                isIn ? const Color(0xFF10B981) : const Color(0xFFEF4444);

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFE5E7EB),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isDark ? 0.22 : 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: iconColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _formatTs(ts),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${isIn ? '+' : ''}$amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: pointsColor,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

