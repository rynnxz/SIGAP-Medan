import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  static const _green  = Color(0xFF10B981);
  static const _amber  = Color(0xFFF59E0B);
  static const _red    = Color(0xFFEF4444);
  static const _blue   = Color(0xFF3B82F6);
  static const _purple = Color(0xFF8B5CF6);

  String _searchQuery = '';
  String _filterType  = 'all';

  // ── helpers ──────────────────────────────────────────────────────────────

  bool _isSuspended(Map<String, dynamic> data) {
    final ts = data['suspendedUntil'] as Timestamp?;
    return ts != null && ts.toDate().isAfter(DateTime.now());
  }

  String _formatTs(dynamic ts) {
    if (ts == null) return '-';
    final dt = ts is Timestamp ? ts.toDate() : (ts as DateTime);
    final d  = dt.day.toString().padLeft(2, '0');
    final mo = ['Jan','Feb','Mar','Apr','Mei','Jun',
                 'Jul','Agu','Sep','Okt','Nov','Des'][dt.month - 1];
    final h  = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$d $mo ${dt.year}, $h:$mi';
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        elevation: 0,
        title: const Text(
          'Kelola Pengguna',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // ── Search + filter ────────────────────────────────────────────────
          Container(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau email…',
                    hintStyle: TextStyle(
                      color: isDark
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF9CA3AF),
                    ),
                    prefixIcon: Icon(
                      LucideIcons.search,
                      size: 18,
                      color: isDark
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF9CA3AF),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.toLowerCase()),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('all',       'Semua',        isDark),
                      _filterChip('user',      'User',         isDark),
                      _filterChip('moderator', 'Moderator',    isDark),
                      _filterChip('verified',  'Terverifikasi',isDark),
                      _filterChip('suspended', 'Suspend',      isDark),
                      _filterChip('banned',    'Banned',       isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark
                ? const Color(0xFF374151)
                : const Color(0xFFE5E7EB),
          ),
          // ── Live list ──────────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(color: _green));
                }

                final allDocs = snapshot.data!.docs;

                var filtered = allDocs.where((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final name =
                      (d['name'] ?? '').toString().toLowerCase();
                  final email =
                      (d['email'] ?? '').toString().toLowerCase();
                  if (_searchQuery.isNotEmpty &&
                      !name.contains(_searchQuery) &&
                      !email.contains(_searchQuery)) { return false; }

                  final banned = d['isBanned'] == true;
                  final suspended = _isSuspended(d);
                  final mod = d['isModerator'] == true;
                  final verified = d['isVerified'] == true;

                  switch (_filterType) {
                    case 'moderator': return mod;
                    case 'verified':  return verified;
                    case 'banned':    return banned;
                    case 'suspended': return suspended;
                    case 'user':
                      return !mod && d['accountType'] != 'admin';
                    default: return true;
                  }
                }).toList();

                filtered.sort((a, b) {
                  final ad = a.data() as Map<String, dynamic>;
                  final bd = b.data() as Map<String, dynamic>;
                  final aBan = ad['isBanned'] == true ? 0 : 1;
                  final bBan = bd['isBanned'] == true ? 0 : 1;
                  if (aBan != bBan) return aBan - bBan;
                  final aSus = _isSuspended(ad) ? 0 : 1;
                  final bSus = _isSuspended(bd) ? 0 : 1;
                  if (aSus != bSus) return aSus - bSus;
                  return (ad['name'] ?? '')
                      .toString()
                      .compareTo((bd['name'] ?? '').toString());
                });

                return Column(
                  children: [
                    _summaryBar(allDocs, isDark),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.userX,
                                      size: 48,
                                      color: isDark
                                          ? const Color(0xFF6B7280)
                                          : const Color(0xFF9CA3AF)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Tidak ada pengguna ditemukan',
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) {
                                final doc = filtered[i];
                                return _userCard(
                                  doc.id,
                                  doc.data() as Map<String, dynamic>,
                                  isDark,
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter chip ────────────────────────────────────────────────────────────

  Widget _filterChip(String value, String label, bool isDark) {
    final selected = _filterType == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filterType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? _green
                : (isDark
                    ? const Color(0xFF374151)
                    : const Color(0xFFF3F4F6)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.normal,
              color: selected
                  ? Colors.white
                  : (isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280)),
            ),
          ),
        ),
      ),
    );
  }

  // ── Summary bar ────────────────────────────────────────────────────────────

  Widget _summaryBar(
      List<QueryDocumentSnapshot> docs, bool isDark) {
    final total     = docs.length;
    final banned    = docs.where((d) =>
        (d.data() as Map)['isBanned'] == true).length;
    final suspended = docs.where((d) =>
        _isSuspended(d.data() as Map<String, dynamic>)).length;
    final mods      = docs.where((d) =>
        (d.data() as Map)['isModerator'] == true).length;

    return Container(
      color: isDark
          ? const Color(0xFF1F2937)
          : const Color(0xFFF3F4F6),
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _summaryPill('Total',   total.toString(),     _blue,   isDark),
          const SizedBox(width: 8),
          _summaryPill('Mod',     mods.toString(),      _purple, isDark),
          const SizedBox(width: 8),
          _summaryPill('Suspend', suspended.toString(), _amber,  isDark),
          const SizedBox(width: 8),
          _summaryPill('Banned',  banned.toString(),    _red,    isDark),
        ],
      ),
    );
  }

  Widget _summaryPill(
      String label, String value, Color color, bool isDark) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(
            text: value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 13),
          ),
          TextSpan(
            text: ' $label',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF6B7280),
            ),
          ),
        ]),
      ),
    );
  }

  // ── User card ──────────────────────────────────────────────────────────────

  Widget _userCard(
      String uid, Map<String, dynamic> data, bool isDark) {
    final banned      = data['isBanned'] == true;
    final suspended   = _isSuspended(data);
    final isModerator = data['isModerator'] == true;
    final isVerified  = data['isVerified'] == true;
    final isAdmin     = data['accountType'] == 'admin';
    final photoUrl    = data['photoURL'] as String?;
    final name        = data['name'] ?? 'Tanpa Nama';
    final email       = data['email'] ?? '';
    final level       = data['level'] ?? 'Pemula';
    final currentXP   = (data['currentXP'] ?? 0) as num;
    final reputation  = (data['reputation'] ?? 0) as num;
    final poinHoras   = (data['poinHoras'] ?? 0) as num;
    final totalRep    = (data['totalReports'] ?? 0) as num;
    final totalCom    = (data['totalComments'] ?? 0) as num;
    final lastActive  = data['lastActiveAt'] as Timestamp?;

    Color? borderColor;
    if (banned) { borderColor = _red; }
    else if (suspended) { borderColor = _amber; }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: borderColor != null
            ? Border.all(
                color: borderColor.withValues(alpha: 0.5), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top: avatar + info + menu ────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isDark
                          ? const Color(0xFF374151)
                          : const Color(0xFFE5E7EB),
                      backgroundImage:
                          (photoUrl != null && photoUrl.isNotEmpty)
                              ? CachedNetworkImageProvider(photoUrl)
                              : null,
                      child:
                          (photoUrl == null || photoUrl.isEmpty)
                              ? Text(
                                  name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF374151),
                                  ),
                                )
                              : null,
                    ),
                    if (banned || suspended)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: banned ? _red : _amber,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF1F2937)
                                  : Colors.white,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            banned
                                ? LucideIcons.ban
                                : LucideIcons.clock,
                            size: 9,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Info column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF111827),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                _showActions(uid, data, isDark),
                            child: Icon(
                              LucideIcons.moreVertical,
                              size: 18,
                              color: isDark
                                  ? const Color(0xFF6B7280)
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Badges
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          _badge(
                            isAdmin
                                ? 'Admin'
                                : isModerator
                                    ? 'Moderator'
                                    : 'User',
                            isAdmin
                                ? _red
                                : isModerator
                                    ? _purple
                                    : _blue,
                          ),
                          if (isVerified)
                            _badge('Terverifikasi', _green),
                          _badge(level, _amber),
                          if (banned) _badge('Banned', _red),
                          if (suspended && !banned)
                            _badge('Suspend', _amber),
                        ],
                      ),
                      if (lastActive != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(LucideIcons.activity,
                                size: 11,
                                color: isDark
                                    ? const Color(0xFF6B7280)
                                    : const Color(0xFF9CA3AF)),
                            const SizedBox(width: 4),
                            Text(
                              'Aktif: ${_formatTs(lastActive)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? const Color(0xFF6B7280)
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Stats row ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF111827).withValues(alpha: 0.6)
                  : const Color(0xFFF9FAFB),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFE5E7EB),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat(LucideIcons.fileText,
                    totalRep.toString(), 'Laporan', isDark),
                _vDivider(isDark),
                _stat(LucideIcons.messageSquare,
                    totalCom.toString(), 'Komentar', isDark),
                _vDivider(isDark),
                _stat(LucideIcons.star,
                    reputation.toString(), 'Reputasi', isDark),
                _vDivider(isDark),
                _stat(LucideIcons.zap,
                    poinHoras.toString(), 'P.Horas', isDark),
                _vDivider(isDark),
                _stat(LucideIcons.trendingUp,
                    currentXP.toString(), 'XP', isDark),
              ],
            ),
          ),
          // ── Suspend notice ───────────────────────────────────────────
          if (suspended && !banned)
            _statusFooter(
              icon: LucideIcons.clock,
              text:
                  'Suspend hingga: ${_formatTs(data['suspendedUntil'])}',
              color: _amber,
            ),
          // ── Ban notice ───────────────────────────────────────────────
          if (banned)
            _statusFooter(
              icon: LucideIcons.ban,
              text: data['banReason'] != null
                  ? 'Alasan: ${data['banReason']}'
                  : 'Akun ini telah dibanned secara permanen',
              color: _red,
            ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      );

  Widget _stat(
      IconData icon, String value, String label, bool isDark) {
    return Column(
      children: [
        Icon(icon,
            size: 13,
            color: isDark
                ? const Color(0xFF6B7280)
                : const Color(0xFF9CA3AF)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color:
                isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark
                ? const Color(0xFF6B7280)
                : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  Widget _vDivider(bool isDark) => Container(
        height: 32,
        width: 1,
        color: isDark
            ? const Color(0xFF374151)
            : const Color(0xFFE5E7EB),
      );

  Widget _statusFooter(
      {required IconData icon,
      required String text,
      required Color color}) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Action bottom sheet ────────────────────────────────────────────────────

  void _showActions(
      String uid, Map<String, dynamic> data, bool isDark) {
    final banned      = data['isBanned'] == true;
    final suspended   = _isSuspended(data);
    final isModerator = data['isModerator'] == true;
    final isVerified  = data['isVerified'] == true;

    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? const Color(0xFF1F2937) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF4B5563)
                      : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // User header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  children: [
                    Icon(LucideIcons.user,
                        size: 15,
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data['name'] ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                  color: isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFE5E7EB)),
              // Suspend / Unsuspend
              if (!banned && !suspended)
                _actionRow(
                  ctx: ctx,
                  icon: LucideIcons.clock,
                  label: 'Suspend Sementara',
                  color: _amber,
                  isDark: isDark,
                  onTap: () => _showSuspendDialog(uid, data, isDark),
                ),
              if (suspended && !banned)
                _actionRow(
                  ctx: ctx,
                  icon: LucideIcons.userCheck,
                  label: 'Cabut Suspend',
                  color: _green,
                  isDark: isDark,
                  onTap: () => _removeSuspend(uid),
                ),
              // Ban / Unban
              if (!banned)
                _actionRow(
                  ctx: ctx,
                  icon: LucideIcons.ban,
                  label: 'Ban Permanen',
                  color: _red,
                  isDark: isDark,
                  onTap: () => _showBanDialog(uid, data, isDark),
                ),
              if (banned)
                _actionRow(
                  ctx: ctx,
                  icon: LucideIcons.userCheck,
                  label: 'Cabut Ban',
                  color: _green,
                  isDark: isDark,
                  onTap: () => _removeBan(uid),
                ),
              Divider(
                  color: isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFE5E7EB)),
              // Verify toggle
              _actionRow(
                ctx: ctx,
                icon: isVerified
                    ? LucideIcons.shield
                    : LucideIcons.shieldCheck,
                label: isVerified
                    ? 'Cabut Verifikasi'
                    : 'Verifikasi Akun',
                color: _green,
                isDark: isDark,
                onTap: () => _toggleVerified(uid, isVerified),
              ),
              // Moderator toggle
              _actionRow(
                ctx: ctx,
                icon: isModerator
                    ? LucideIcons.userMinus
                    : LucideIcons.userPlus,
                label: isModerator
                    ? 'Cabut Status Moderator'
                    : 'Jadikan Moderator',
                color: _purple,
                isDark: isDark,
                onTap: () => _toggleModerator(uid, isModerator),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionRow({
    required BuildContext ctx,
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(ctx);
        onTap();
      },
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color:
                    isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showSuspendDialog(
      String uid, Map<String, dynamic> data, bool isDark) {
    final durations = [
      {'label': '30 Menit', 'minutes': 30},
      {'label': '1 Jam',    'minutes': 60},
      {'label': '3 Jam',    'minutes': 180},
      {'label': '24 Jam',   'minutes': 1440},
      {'label': '3 Hari',   'minutes': 4320},
      {'label': '7 Hari',   'minutes': 10080},
      {'label': '30 Hari',  'minutes': 43200},
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? const Color(0xFF1F2937) : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(LucideIcons.clock, size: 20, color: _amber),
          const SizedBox(width: 8),
          const Text('Suspend Pengguna'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih durasi suspend untuk "${data['name'] ?? 'pengguna ini'}":',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: durations.map((d) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    _suspendUser(uid, d['minutes'] as int,
                        d['label'] as String);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: _amber.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      d['label'] as String,
                      style: TextStyle(
                          color: _amber,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: TextStyle(
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280))),
          ),
        ],
      ),
    );
  }

  void _showBanDialog(
      String uid, Map<String, dynamic> data, bool isDark) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? const Color(0xFF1F2937) : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(LucideIcons.ban, size: 20, color: _red),
          const SizedBox(width: 8),
          const Text('Ban Pengguna'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '"${data['name'] ?? ''}" akan diblokir secara permanen.',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Alasan ban (opsional)',
                hintStyle: TextStyle(
                  color: isDark
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF9CA3AF),
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF374151)
                    : const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: TextStyle(
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _banUser(uid, controller.text.trim());
            },
            child: const Text('Ban'),
          ),
        ],
      ),
    );
  }

  // ── Firestore actions ──────────────────────────────────────────────────────

  Future<void> _suspendUser(
      String uid, int minutes, String label) async {
    final until =
        DateTime.now().add(Duration(minutes: minutes));
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'suspendedUntil': Timestamp.fromDate(until)});
    _snack('Pengguna disuspend selama $label', _amber);
  }

  Future<void> _removeSuspend(String uid) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'suspendedUntil': FieldValue.delete()});
    _snack('Suspend dicabut', _green);
  }

  Future<void> _banUser(String uid, String reason) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({
      'isBanned': true,
      'banReason': reason.isEmpty ? null : reason,
      'bannedAt': Timestamp.now(),
    });
    _snack('Pengguna telah dibanned', _red);
  }

  Future<void> _removeBan(String uid) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({
      'isBanned': false,
      'banReason': FieldValue.delete(),
      'bannedAt': FieldValue.delete(),
    });
    _snack('Ban dicabut', _green);
  }

  Future<void> _toggleVerified(String uid, bool current) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'isVerified': !current});
    _snack(
        !current ? 'Akun diverifikasi' : 'Verifikasi dicabut',
        _green);
  }

  Future<void> _toggleModerator(String uid, bool current) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'isModerator': !current});
    _snack(
        !current
            ? 'Pengguna dijadikan moderator'
            : 'Status moderator dicabut',
        _purple);
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
    ));
  }
}

