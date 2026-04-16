import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminReportedCommentsScreen extends StatefulWidget {
  const AdminReportedCommentsScreen({super.key});

  @override
  State<AdminReportedCommentsScreen> createState() =>
      _AdminReportedCommentsScreenState();
}

class _AdminReportedCommentsScreenState
    extends State<AdminReportedCommentsScreen> {
  final _db = FirebaseFirestore.instance;
  bool _isProcessing = false;

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '-';
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(ts.toDate());
  }

  Future<void> _dismiss(String docId) async {
    setState(() => _isProcessing = true);
    await _db.collection('comment_reports').doc(docId).update({'status': 'dismissed'});
    setState(() => _isProcessing = false);
    if (mounted) _snack('Laporan diabaikan', const Color(0xFF6B7280));
  }

  Future<void> _deleteComment(String docId, String reportId, String commentId) async {
    setState(() => _isProcessing = true);

    final batch = _db.batch();

    // Delete the actual comment
    final commentRef = _db
        .collection('reports')
        .doc(reportId)
        .collection('comments')
        .doc(commentId);
    batch.delete(commentRef);

    // Mark all pending reports for this comment as 'removed'
    final related = await _db
        .collection('comment_reports')
        .where('commentId', isEqualTo: commentId)
        .where('status', isEqualTo: 'pending')
        .get();
    for (final d in related.docs) {
      batch.update(d.reference, {'status': 'removed'});
    }

    await batch.commit();
    setState(() => _isProcessing = false);
    if (mounted) _snack('Komentar dihapus', const Color(0xFFEF4444));
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
    final cardBg = isDark ? const Color(0xFF1F2937) : Colors.white;
    final textColor  = isDark ? Colors.white : const Color(0xFF1F2937);
    final mutedColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Laporan Komentar',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('comment_reports')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Gagal memuat data:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.checkCircle, size: 48, color: const Color(0xFF10B981).withValues(alpha: 0.6)),
                  const SizedBox(height: 12),
                  Text('Tidak ada laporan yang perlu ditinjau',
                      style: TextStyle(color: mutedColor, fontSize: 14)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final aTs = (a.data() as Map)['createdAt'] as Timestamp?;
              final bTs = (b.data() as Map)['createdAt'] as Timestamp?;
              if (aTs == null && bTs == null) return 0;
              if (aTs == null) return 1;
              if (bTs == null) return -1;
              return bTs.compareTo(aTs);
            });

          return AbsorbPointer(
            absorbing: _isProcessing,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc  = docs[index];
                final data = doc.data() as Map<String, dynamic>;

                final commentText      = data['commentText']      as String? ?? '';
                final commentOwnerName = data['commentOwnerName'] as String? ?? 'Anonim';
                final commentOwnerId   = data['commentOwnerId']   as String? ?? '';
                final reason           = data['reason']           as String? ?? '-';
                final reportId         = data['reportId']         as String? ?? '';
                final commentId        = data['commentId']        as String? ?? '';
                final createdAt        = data['createdAt']        as Timestamp?;

                return Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: isDark
                        ? Border.all(color: const Color(0xFF374151))
                        : null,
                    boxShadow: isDark
                        ? null
                        : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: owner + timestamp
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Pending',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Oleh: $commentOwnerName',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatDate(createdAt),
                            style: TextStyle(color: mutedColor, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Comment text
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF111827)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          commentText.isEmpty ? '(komentar kosong)' : commentText,
                          style: TextStyle(
                            color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                            fontSize: 13,
                            fontStyle: commentText.isEmpty ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Reason
                      Row(
                        children: [
                          Icon(LucideIcons.alertTriangle, size: 13, color: const Color(0xFFF59E0B)),
                          const SizedBox(width: 6),
                          Text(
                            'Alasan: $reason',
                            style: TextStyle(
                              color: mutedColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Actions row 1: report actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _dismiss(doc.id),
                              icon: Icon(LucideIcons.x, size: 14, color: mutedColor),
                              label: Text('Abaikan', style: TextStyle(color: mutedColor, fontSize: 13)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: mutedColor.withValues(alpha: 0.4)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: reportId.isEmpty || commentId.isEmpty
                                  ? null
                                  : () => _showDeleteConfirm(doc.id, reportId, commentId, isDark),
                              icon: const Icon(LucideIcons.trash2, size: 14, color: Colors.white),
                              label: const Text('Hapus Komentar',
                                  style: TextStyle(color: Colors.white, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4444),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Actions row 2: owner sanctions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: commentOwnerId.isEmpty
                                  ? null
                                  : () => _showSuspendDialog(
                                        commentOwnerId,
                                        commentOwnerName,
                                        isDark,
                                      ),
                              icon: const Icon(LucideIcons.clock,
                                  size: 14, color: Color(0xFFF59E0B)),
                              label: const Text('Suspend',
                                  style: TextStyle(
                                      color: Color(0xFFF59E0B), fontSize: 13)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Color(0xFFF59E0B), width: 0.8),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: commentOwnerId.isEmpty
                                  ? null
                                  : () => _showBanDialog(
                                        commentOwnerId,
                                        commentOwnerName,
                                        isDark,
                                      ),
                              icon: const Icon(LucideIcons.ban,
                                  size: 14, color: Colors.white),
                              label: const Text('Ban Permanen',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C3AED),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ── Suspend dialog ─────────────────────────────────────────────────────────

  void _showSuspendDialog(String uid, String name, bool isDark) {
    final durations = [
      {'label': '30 Menit', 'minutes': 30},
      {'label': '1 Jam',    'minutes': 60},
      {'label': '3 Jam',    'minutes': 180},
      {'label': '24 Jam',   'minutes': 1440},
      {'label': '3 Hari',   'minutes': 4320},
      {'label': '7 Hari',   'minutes': 10080},
      {'label': '30 Hari',  'minutes': 43200},
    ];
    final amber = const Color(0xFFF59E0B);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(LucideIcons.clock, size: 20, color: amber),
          const SizedBox(width: 8),
          const Text('Suspend Pengguna'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih durasi suspend untuk "$name":',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
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
                    _suspendUser(uid, d['minutes'] as int, d['label'] as String);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: amber.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      d['label'] as String,
                      style: TextStyle(
                          color: amber,
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

  // ── Ban dialog ──────────────────────────────────────────────────────────────

  void _showBanDialog(String uid, String name, bool isDark) {
    final controller = TextEditingController();
    final red = const Color(0xFF7C3AED);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(LucideIcons.ban, size: 20, color: red),
          const SizedBox(width: 8),
          const Text('Ban Pengguna'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '"$name" akan diblokir secara permanen.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Alasan ban (opsional)',
                hintStyle: TextStyle(
                  color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
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
              backgroundColor: red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  // ── Firestore actions ───────────────────────────────────────────────────────

  Future<void> _suspendUser(String uid, int minutes, String label) async {
    final until = DateTime.now().add(Duration(minutes: minutes));
    await _db
        .collection('users')
        .doc(uid)
        .update({'suspendedUntil': Timestamp.fromDate(until)});
    if (mounted) _snack('Pengguna disuspend selama $label', const Color(0xFFF59E0B));
  }

  Future<void> _banUser(String uid, String reason) async {
    await _db.collection('users').doc(uid).update({
      'isBanned': true,
      'banReason': reason.isEmpty ? null : reason,
      'bannedAt': Timestamp.now(),
    });
    if (mounted) _snack('Pengguna telah dibanned', const Color(0xFF7C3AED));
  }

  // ── Delete confirm dialog ───────────────────────────────────────────────────

  void _showDeleteConfirm(String docId, String reportId, String commentId, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Komentar?',
            style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
        content: Text(
          'Komentar ini akan dihapus permanen dan semua laporan terkait ditutup.',
          style: TextStyle(
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: TextStyle(
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteComment(docId, reportId, commentId);
            },
            child: const Text('Hapus',
                style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
