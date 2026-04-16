import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/cloudinary_service.dart';
import '../services/notification_service.dart';
import '../services/poin_horas_service.dart';

class DinasScreen extends StatefulWidget {
  const DinasScreen({super.key});

  @override
  State<DinasScreen> createState() => _DinasScreenState();
}

class _DinasScreenState extends State<DinasScreen> {
  static const _green  = Color(0xFF10B981);
  static const _amber  = Color(0xFFF59E0B);
  static const _red    = Color(0xFFEF4444);
  static const _blue   = Color(0xFF3B82F6);

  String? _dinasName;
  String? _userName;
  bool    _isLoadingProfile = true;
  bool    _isUpdating       = false;
  String  _filterStatus     = 'all';

  final _cloudinary = CloudinaryService();
  final _picker     = ImagePicker();

  // ── Init ─────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    if (mounted) {
      setState(() {
        _dinasName        = data?['dinasName'] as String?
            ?? data?['name']  as String?
            ?? 'Dinas';
        _userName         = data?['name'] as String? ?? 'Pengguna';
        _isLoadingProfile = false;
      });
    }
  }

  // ── Firestore query ────────────────────────────────────────────────────────

  Stream<QuerySnapshot<Map<String, dynamic>>> get _reportStream {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection('reports')
        .where('dinasTerkait', isEqualTo: _dinasName)
        .orderBy('createdAt', descending: true);
    if (_filterStatus != 'all') {
      q = q.where('status', isEqualTo: _filterStatus);
    }
    return q.snapshots();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _updateStatus(
    String id,
    String status, {
    String reporterUserId = '',
    String reportTitle    = '',
  }) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      final update = <String, dynamic>{
        'status':    status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (status == 'Diproses') update['processedAt'] = FieldValue.serverTimestamp();
      if (status == 'Selesai')  update['completedAt']  = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance
          .collection('reports')
          .doc(id)
          .update(update);

      if (status == 'Selesai' && reporterUserId.isNotEmpty) {
        await PoinHorasService.awardForResolved(reporterUserId, id);
      }
      if (reporterUserId.isNotEmpty) {
        await NotificationService.notifyReportStatus(
          userId:      reporterUserId,
          reportTitle: reportTitle.isNotEmpty ? reportTitle : 'Laporan kamu',
          newStatus:   status,
          reportId:    id,
        );
      }
      _snack('Status diubah ke $status', _statusColor(status));
    } catch (e) {
      _snack('Gagal: $e', _red);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _uploadCompletionPhoto(String id) async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) return;
    setState(() => _isUpdating = true);
    try {
      final result = await _cloudinary.uploadCompletionPhoto(
          imageFile: File(picked.path));
      if (result['success'] == true) {
        await FirebaseFirestore.instance
            .collection('reports')
            .doc(id)
            .update({'completionImageUrl': result['url']});
        _snack('Bukti berhasil diunggah', _green);
      } else {
        _snack('Upload gagal: ${result['error']}', _red);
      }
    } catch (e) {
      _snack('Error: $e', _red);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _statusColor(String? s) {
    switch (s) {
      case 'Selesai':  return _green;
      case 'Diproses': return _amber;
      case 'Dihapus':  return _red;
      default:         return _blue;
    }
  }

  String _formatTs(dynamic ts) {
    if (ts == null) return '-';
    final dt = ts is Timestamp ? ts.toDate() : (ts as DateTime);
    final d  = dt.day.toString().padLeft(2, '0');
    const mo = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final h  = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$d ${mo[dt.month]} ${dt.year}, $h:$mi';
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(LucideIcons.logOut, size: 18, color: Color(0xFFEF4444)),
          SizedBox(width: 8),
          Text('Keluar'),
        ]),
        content: const Text('Yakin ingin keluar dari Portal Dinas?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
    final card   = isDark ? const Color(0xFF1F2937) : Colors.white;

    if (_isLoadingProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          _buildFilterRow(isDark),
          Expanded(
            child: _dinasName == null
                ? _emptyState(isDark, 'Nama dinas tidak terdaftar.\nHubungi administrator.')
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _reportStream,
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final docs = snap.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return _emptyState(isDark,
                            'Belum ada laporan yang\nditugaskan ke dinas Anda.');
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        itemBuilder: (ctx, i) => _reportCard(
                          docs[i].id,
                          docs[i].data(),
                          isDark,
                          card,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor:
          isDark ? const Color(0xFF1F2937) : Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.building2,
                size: 18, color: _blue),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _dinasName ?? 'Portal Dinas',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
              Text(
                'Laporan Ditugaskan · $_userName',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: _showLogoutDialog,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.logOut,
                  size: 18, color: _red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow(bool isDark) {
    final chips = [
      ('Semua',    'all',       _blue),
      ('Diproses', 'Diproses',  _amber),
      ('Selesai',  'Selesai',   _green),
    ];
    return Container(
      color: isDark ? const Color(0xFF1F2937) : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: chips.map((t) {
          final active = _filterStatus == t.$2;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filterStatus = t.$2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: active
                      ? t.$3
                      : (isDark
                          ? const Color(0xFF374151)
                          : const Color(0xFFF3F4F6)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  t.$1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active
                        ? Colors.white
                        : (isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Report Card ────────────────────────────────────────────────────────────

  Widget _reportCard(
      String id, Map<String, dynamic> data, bool isDark, Color card) {
    final status         = data['status']       as String? ?? 'Menunggu';
    final sc             = _statusColor(status);
    final title          = data['title']        as String? ?? 'Tanpa Judul';
    final category       = data['category']     as String? ?? '';
    final subCat         = data['subCategory']  as String? ?? '';
    final address        = data['address']      as String? ?? '-';
    final reporter       = data['reporterName'] as String? ?? 'Anonymous';
    final reporterUserId = data['userId']       as String? ?? '';
    final imageUrl       = data['imageUrl']     as String?;
    final completionUrl  = data['completionImageUrl'] as String?;
    final border    = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final textMuted = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.clipboardList,
                      size: 16, color: sc),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (category.isNotEmpty)
                        Text(
                          subCat.isNotEmpty
                              ? '$category · $subCat'
                              : category,
                          style: TextStyle(
                              fontSize: 11,
                              color: sc,
                              fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: sc.withValues(alpha: 0.3)),
                  ),
                  child: Text(status,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: sc)),
                ),
              ],
            ),
          ),

          // ── Report photo ───────────────────────────────────────
          if (imageUrl != null && imageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 130,
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFE5E7EB),
                  ),
                  errorWidget: (_, __, ___) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),

          // ── Meta ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _metaRow(LucideIcons.mapPin, address, textMuted),
                const SizedBox(height: 4),
                _metaRow(LucideIcons.user, reporter, textMuted),
                const SizedBox(height: 4),
                _metaRow(LucideIcons.calendar,
                    _formatTs(data['reportedAt'] ?? data['createdAt']),
                    textMuted),
              ],
            ),
          ),

          // ── Completion proof ───────────────────────────────────
          if (status == 'Selesai')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: completionUrl != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(LucideIcons.camera,
                              size: 12, color: _green),
                          const SizedBox(width: 5),
                          const Text('Bukti Penyelesaian',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _green)),
                        ]),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: completionUrl,
                            height: 110,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              height: 110,
                              color: isDark
                                  ? const Color(0xFF374151)
                                  : const Color(0xFFE5E7EB),
                            ),
                            errorWidget: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    )
                  : GestureDetector(
                      onTap: _isUpdating
                          ? null
                          : () => _uploadCompletionPhoto(id),
                      child: Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _green.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: const [
                            Icon(LucideIcons.camera,
                                size: 14, color: _green),
                            SizedBox(width: 6),
                            Text('Upload Bukti Selesai',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _green)),
                          ],
                        ),
                      ),
                    ),
            ),

          // ── Action buttons ─────────────────────────────────────
          if (status != 'Selesai' && status != 'Dihapus')
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  if (status != 'Diproses')
                    Expanded(
                      child: _actionBtn(
                        label: 'Tandai Diproses',
                        icon: LucideIcons.clock,
                        color: _amber,
                        onTap: () => _updateStatus(id, 'Diproses',
                            reporterUserId: reporterUserId,
                            reportTitle: title),
                      ),
                    ),
                  if (status != 'Diproses') const SizedBox(width: 8),
                  Expanded(
                    child: _actionBtn(
                      label: 'Tandai Selesai',
                      icon: LucideIcons.checkCircle2,
                      color: _green,
                      onTap: () => _updateStatus(id, 'Selesai',
                          reporterUserId: reporterUserId,
                          reportTitle: title),
                    ),
                  ),
                ],
              ),
            ),

          if (status == 'Selesai')
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: _green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(LucideIcons.checkCircle2,
                        size: 14, color: _green),
                    SizedBox(width: 6),
                    Text('Laporan Selesai',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _green)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String text, Color color) => Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 11, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      );

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: _isUpdating ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
        ),
      );

  Widget _emptyState(bool isDark, String msg) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.clipboardList,
                size: 48,
                color: isDark
                    ? const Color(0xFF374151)
                    : const Color(0xFFD1D5DB)),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? const Color(0xFF6B7280)
                    : const Color(0xFF9CA3AF),
                height: 1.5,
              ),
            ),
          ],
        ),
      );
}
