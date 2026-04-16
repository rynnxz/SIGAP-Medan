import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminStatsScreen extends StatelessWidget {
  const AdminStatsScreen({super.key});

  static const _green  = Color(0xFF10B981);
  static const _amber  = Color(0xFFF59E0B);
  static const _red    = Color(0xFFEF4444);
  static const _blue   = Color(0xFF3B82F6);
  static const _purple = Color(0xFF8B5CF6);
  static const _teal   = Color(0xFF14B8A6);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final db     = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft,
              color: isDark ? Colors.white : const Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Statistik & Analitik',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1,
              color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection('users').snapshots(),
        builder: (_, usersSnap) => StreamBuilder<QuerySnapshot>(
          stream: db.collection('reports').snapshots(),
          builder: (_, reportsSnap) => StreamBuilder<QuerySnapshot>(
            stream: db.collection('destinations').snapshots(),
            builder: (_, destSnap) {
              if (!usersSnap.hasData ||
                  !reportsSnap.hasData ||
                  !destSnap.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: _green));
              }
              final users   = usersSnap.data!.docs;
              final reports = reportsSnap.data!.docs;
              final dests   = destSnap.data!.docs;
              return _StatsBody(
                  users: users, reports: reports, dests: dests, isDark: isDark);
            },
          ),
        ),
      ),
    );
  }
}

// ── Body ─────────────────────────────────────────────────────────────────────

class _StatsBody extends StatelessWidget {
  const _StatsBody({
    required this.users,
    required this.reports,
    required this.dests,
    required this.isDark,
  });

  final List<QueryDocumentSnapshot> users;
  final List<QueryDocumentSnapshot> reports;
  final List<QueryDocumentSnapshot> dests;
  final bool isDark;

  static const _green  = AdminStatsScreen._green;
  static const _amber  = AdminStatsScreen._amber;
  static const _red    = AdminStatsScreen._red;
  static const _blue   = AdminStatsScreen._blue;
  static const _purple = AdminStatsScreen._purple;
  static const _teal   = AdminStatsScreen._teal;

  // ── computed ───────────────────────────────────────────────────────────────

  Map<String, dynamic> get _reportStats {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    int menunggu = 0, diproses = 0, selesai = 0, dihapus = 0, recent = 0;
    for (final r in reports) {
      final d      = r.data() as Map<String, dynamic>;
      final status = d['status'] as String? ?? 'Menunggu';
      switch (status) {
        case 'Menunggu':  menunggu++;  break;
        case 'Diproses':  diproses++;  break;
        case 'Selesai':   selesai++;   break;
        case 'Dihapus':   dihapus++;   break;
      }
      final ts = d['createdAt'] as Timestamp?;
      if (ts != null && ts.toDate().isAfter(sevenDaysAgo)) recent++;
    }
    final active      = menunggu + diproses;
    final nonDeleted  = reports.length - dihapus;
    final resolveRate = nonDeleted > 0 ? (selesai / nonDeleted * 100) : 0.0;
    return {
      'menunggu': menunggu, 'diproses': diproses,
      'selesai': selesai,   'dihapus': dihapus,
      'active': active,     'recent': recent,
      'resolveRate': resolveRate, 'nonDeleted': nonDeleted,
    };
  }

  Map<String, int> get _reportCategories {
    final map = <String, int>{};
    for (final r in reports) {
      final d   = r.data() as Map<String, dynamic>;
      if ((d['status'] as String?) == 'Dihapus') continue;
      final cat = (d['category'] as String?) ?? 'Lainnya';
      map[cat] = (map[cat] ?? 0) + 1;
    }
    final sorted = Map.fromEntries(
        map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
    return sorted;
  }

  Map<String, dynamic> get _userStats {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    int admins = 0, newUsers = 0;
    final levels = <String, int>{};
    int totalCheckIns = 0;
    for (final u in users) {
      final d = u.data() as Map<String, dynamic>;
      if ((d['accountType'] as String?) == 'admin') admins++;
      final ts = d['createdAt'] as Timestamp?;
      if (ts != null && ts.toDate().isAfter(sevenDaysAgo)) newUsers++;
      final lvl = (d['level'] as String?) ?? 'Pemula';
      levels[lvl] = (levels[lvl] ?? 0) + 1;
      totalCheckIns += (d['totalCheckIns'] as int?) ?? 0;
    }
    return {
      'admins': admins, 'newUsers': newUsers,
      'levels': levels, 'totalCheckIns': totalCheckIns,
    };
  }

  Map<String, dynamic> get _destStats {
    int active = 0, inactive = 0;
    final cats = <String, int>{};
    for (final d in dests) {
      final data = d.data() as Map<String, dynamic>;
      if (data['isActive'] != false) {
        active++;
      } else {
        inactive++;
      }
      final cat = (data['category'] as String?) ?? 'Lainnya';
      cats[cat] = (cats[cat] ?? 0) + 1;
    }
    final sortedCats = Map.fromEntries(
        cats.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
    return {'active': active, 'inactive': inactive, 'cats': sortedCats};
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final rs  = _reportStats;
    final us  = _userStats;
    final ds  = _destStats;
    final rc  = _reportCategories;
    final lvl = us['levels'] as Map<String, int>;
    final dc  = ds['cats']   as Map<String, int>;

    final card   = isDark ? const Color(0xFF1F2937) : Colors.white;
    final divCol = isDark ? const Color(0xFF374151)  : const Color(0xFFE5E7EB);
    final textCol  = isDark ? Colors.white : const Color(0xFF111827);
    final mutedCol = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      children: [

        // ── KPI overview ──────────────────────────────────────────────────
        _sectionLabel('Ringkasan', textCol),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _kpiCard(
            label: 'Laporan Aktif',
            value: '${rs['active']}',
            sub: '${rs['menunggu']} menunggu · ${rs['diproses']} diproses',
            icon: LucideIcons.alertCircle, color: _amber, card: card,
            textCol: textCol, mutedCol: mutedCol,
          )),
          const SizedBox(width: 12),
          Expanded(child: _kpiCard(
            label: 'Tingkat Selesai',
            value: '${(rs['resolveRate'] as double).toStringAsFixed(1)}%',
            sub: '${rs['selesai']} dari ${rs['nonDeleted']} laporan',
            icon: LucideIcons.checkCircle2, color: _green, card: card,
            textCol: textCol, mutedCol: mutedCol,
          )),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _kpiCard(
            label: 'Total Pengguna',
            value: '${users.length}',
            sub: '+${us['newUsers']} minggu ini',
            icon: LucideIcons.users, color: _blue, card: card,
            textCol: textCol, mutedCol: mutedCol,
          )),
          const SizedBox(width: 12),
          Expanded(child: _kpiCard(
            label: 'Check-in Total',
            value: '${us['totalCheckIns']}',
            sub: '${ds['active']} destinasi aktif',
            icon: LucideIcons.mapPin, color: _teal, card: card,
            textCol: textCol, mutedCol: mutedCol,
          )),
        ]),

        const SizedBox(height: 24),

        // ── Status Laporan ────────────────────────────────────────────────
        _sectionCard(
          title: 'Status Laporan',
          icon: LucideIcons.fileText,
          card: card, divCol: divCol, textCol: textCol, mutedCol: mutedCol,
          trailing: _badge('+${rs['recent']} minggu ini', _blue, isDark),
          child: Column(children: [
            _bar('Menunggu',  rs['menunggu'] as int, reports.length, _red,    textCol, mutedCol, isDark),
            const SizedBox(height: 10),
            _bar('Diproses',  rs['diproses'] as int, reports.length, _amber,  textCol, mutedCol, isDark),
            const SizedBox(height: 10),
            _bar('Selesai',   rs['selesai']  as int, reports.length, _green,  textCol, mutedCol, isDark),
            const SizedBox(height: 10),
            _bar('Dihapus',   rs['dihapus']  as int, reports.length, mutedCol, textCol, mutedCol, isDark),
          ]),
        ),

        const SizedBox(height: 16),

        // ── Kategori Laporan ──────────────────────────────────────────────
        _sectionCard(
          title: 'Kategori Laporan',
          icon: LucideIcons.layoutGrid,
          card: card, divCol: divCol, textCol: textCol, mutedCol: mutedCol,
          child: rc.isEmpty
            ? _emptyHint('Belum ada laporan', mutedCol)
            : Column(children: [
                for (final e in rc.entries) ...[
                  _bar(
                    e.key.split(' & ').first,
                    e.value,
                    rs['nonDeleted'] as int,
                    _catColor(e.key),
                    textCol, mutedCol, isDark,
                  ),
                  if (e.key != rc.keys.last) const SizedBox(height: 10),
                ],
              ]),
        ),

        const SizedBox(height: 16),

        // ── Pengguna ──────────────────────────────────────────────────────
        _sectionCard(
          title: 'Pengguna',
          icon: LucideIcons.users,
          card: card, divCol: divCol, textCol: textCol, mutedCol: mutedCol,
          trailing: _badge('${us['admins']} admin', _purple, isDark),
          child: Column(children: [
            for (final entry in _levelOrder.entries) ...[
              _bar(
                entry.key,
                lvl[entry.key] ?? 0,
                users.length,
                entry.value,
                textCol, mutedCol, isDark,
              ),
              if (entry.key != _levelOrder.keys.last) const SizedBox(height: 10),
            ],
          ]),
        ),

        const SizedBox(height: 16),

        // ── Destinasi ─────────────────────────────────────────────────────
        _sectionCard(
          title: 'Destinasi',
          icon: LucideIcons.mapPin,
          card: card, divCol: divCol, textCol: textCol, mutedCol: mutedCol,
          child: Column(children: [
            Row(children: [
              Expanded(child: _miniStat('Aktif',    '${ds['active']}',   _green,  card, textCol, mutedCol)),
              const SizedBox(width: 12),
              Expanded(child: _miniStat('Nonaktif', '${ds['inactive']}', mutedCol, card, textCol, mutedCol)),
            ]),
            Divider(height: 24, color: divCol),
            for (final e in dc.entries) ...[
              _bar(e.key, e.value, dests.length, _teal, textCol, mutedCol, isDark),
              if (e.key != dc.keys.last) const SizedBox(height: 10),
            ],
          ]),
        ),

      ],
    );
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  static const _levelOrder = <String, Color>{
    'Pemula':        Color(0xFF9CA3AF),
    'Muda Bangsa':   Color(0xFF3B82F6),
    'Pejuang Kota':  Color(0xFF10B981),
    'Wali Kota':     Color(0xFFF59E0B),
    'Penjaga Kota':  Color(0xFF8B5CF6),
  };

  static Color _catColor(String cat) {
    if (cat.contains('Lingkungan')) return const Color(0xFF10B981);
    if (cat.contains('Transportasi')) return const Color(0xFF3B82F6);
    if (cat.contains('Layanan')) return const Color(0xFF8B5CF6);
    if (cat.contains('Ketertiban')) return const Color(0xFFF59E0B);
    return const Color(0xFF6B7280);
  }

  Widget _sectionLabel(String text, Color textCol) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: textCol.withOpacity(0.5),
          letterSpacing: 0.8,
        ),
      );

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    required Color card,
    required Color divCol,
    required Color textCol,
    required Color mutedCol,
    Widget? trailing,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(children: [
                Icon(icon, size: 16, color: mutedCol),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textCol)),
                const Spacer(),
                if (trailing != null) trailing,
              ]),
            ),
            Divider(height: 1, color: divCol),
            Padding(padding: const EdgeInsets.all(16), child: child),
          ],
        ),
      );

  Widget _kpiCard({
    required String label,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
    required Color card,
    required Color textCol,
    required Color mutedCol,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: textCol)),
          const SizedBox(height: 2),
          Text(sub,
              style: TextStyle(fontSize: 10, color: mutedCol),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ]),
      );

  Widget _bar(String label, int value, int total, Color color,
      Color textCol, Color mutedCol, bool isDark) {
    final pct      = total > 0 ? value / total : 0.0;
    final pctLabel = total > 0 ? '${(pct * 100).toStringAsFixed(1)}%' : '0%';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500, color: textCol)),
        Text('$value  ($pctLabel)',
            style: TextStyle(fontSize: 12, color: mutedCol)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: pct,
          minHeight: 7,
          backgroundColor:
              isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    ]);
  }

  Widget _badge(String text, Color color, bool isDark) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      );

  Widget _miniStat(String label, String value, Color color, Color card,
      Color textCol, Color mutedCol) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 12, color: mutedCol)),
        ]),
      );

  Widget _emptyHint(String text, Color mutedCol) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(text, style: TextStyle(fontSize: 13, color: mutedCol)),
        ),
      );
}
