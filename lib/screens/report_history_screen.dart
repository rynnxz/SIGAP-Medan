import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'report_detail_screen_firestore.dart';

class ReportHistoryScreen extends StatelessWidget {
  const ReportHistoryScreen({super.key});

  String _formatTs(dynamic ts) {
    if (ts == null) return '-';
    final dt = ts is Timestamp ? ts.toDate() : DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final d  = dt.day.toString().padLeft(2, '0');
    final mo = months[dt.month - 1];
    final h  = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$d $mo ${dt.year}  •  $h:$mi';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid    = FirebaseAuth.instance.currentUser?.uid;

    final bg      = isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
    final surface = isDark ? const Color(0xFF1F2937) : Colors.white;
    final textCol = isDark ? Colors.white : const Color(0xFF111827);
    final mutedCol = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final divCol  = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textCol),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Log Laporan Dihapus',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textCol,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: divCol),
        ),
      ),
      body: uid == null
          ? _emptyState(isDark, mutedCol, 'Kamu belum login.')
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reports')
                  .where('userId', isEqualTo: uid)
                  .where('status', isEqualTo: 'Dihapus')
                  .orderBy('deletedAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFEF4444)),
                  );
                }

                final docs = snap.data?.docs ?? [];

                if (docs.isEmpty) {
                  return _emptyState(
                    isDark,
                    mutedCol,
                    'Tidak ada laporan yang dihapus.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final doc  = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final title       = (data['title'] ?? 'Tanpa Judul').toString();
                    final category    = (data['category'] ?? '').toString();
                    final subCategory = (data['subCategory'] ?? '').toString();
                    final address     = (data['address'] ?? '').toString();
                    final reason      = (data['deleteReason'] ?? '').toString();
                    final deletedAt   = data['deletedAt'];

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportDetailScreenFirestore(
                            reportId: doc.id,
                          ),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withOpacity(0.25),
                          ),
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
                            // ── Header strip ───────────────────────────────
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withOpacity(0.08),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(14)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.trash2,
                                      size: 14, color: Color(0xFFEF4444)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Dihapus Admin',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _formatTs(deletedAt),
                                    style: TextStyle(
                                        fontSize: 10, color: mutedCol),
                                  ),
                                ],
                              ),
                            ),
                            // ── Body ───────────────────────────────────────
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: textCol,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  // Category badge
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEF4444)
                                              .withOpacity(0.10),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          subCategory.isNotEmpty
                                              ? subCategory
                                              : category,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFFEF4444),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (address.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(LucideIcons.mapPin,
                                            size: 12, color: mutedCol),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            address,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: mutedCol),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (reason.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF374151)
                                            : const Color(0xFFFEF2F2),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                              LucideIcons.messageSquare,
                                              size: 13,
                                              color: Color(0xFFEF4444)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Alasan penghapusan',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: const Color(
                                                        0xFFEF4444),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  reason,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isDark
                                                        ? const Color(
                                                            0xFFD1D5DB)
                                                        : const Color(
                                                            0xFF374151),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  // Poin penalty note
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.alertTriangle,
                                          size: 12, color: Color(0xFFF59E0B)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '-10 Poin Horas telah dipotong',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: const Color(0xFFF59E0B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'Lihat detail →',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: mutedCol,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _emptyState(bool isDark, Color mutedCol, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.checkCircle2,
            size: 56,
            color: isDark
                ? const Color(0xFF374151)
                : const Color(0xFFD1D5DB),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: mutedCol),
          ),
        ],
      ),
    );
  }
}
