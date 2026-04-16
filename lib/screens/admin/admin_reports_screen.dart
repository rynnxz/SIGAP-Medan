import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/cloudinary_service.dart';
import '../../services/notification_service.dart';
import '../../services/poin_horas_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  static const _green  = Color(0xFF10B981);
  static const _amber  = Color(0xFFF59E0B);
  static const _red    = Color(0xFFEF4444);
  static const _blue   = Color(0xFF3B82F6);

  static const _dinasList = [
    'Dinas PU (Pekerjaan Umum)',
    'Dinas Kebersihan & Pertamanan',
    'Dinas Perhubungan',
    'Dinas Lingkungan Hidup & Kehutanan',
    'Dinas Tata Kota & Perumahan',
    'Satuan Polisi Pamong Praja',
    'BPBD (Penanggulangan Bencana)',
    'Dinas Sosial',
    'PLN',
    'PDAM Tirtanadi',
  ];

  // ── pagination state ───────────────────────────────────────────────────────
  static const int _pageSize = 8;

  /// Ordered list of doc IDs in current page set.
  final List<String> _docIds = [];

  /// Mutable local cache of doc data — updated in-place on status changes.
  final Map<String, Map<String, dynamic>> _docData = {};

  /// Cursor for the next page query.
  DocumentSnapshot? _lastDoc;

  bool _hasMore           = true;
  bool _isInitialLoading  = true;
  bool _isLoadingMore     = false;
  bool _isUpdating        = false;

  // ── filters ────────────────────────────────────────────────────────────────
  String _filterStatus = 'all';
  String _searchQuery  = '';

  late final ScrollController _scrollCtrl;
  final _picker     = ImagePicker();
  final _cloudinary = CloudinaryService();

  // ── lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController()..addListener(_onScroll);
    _loadPage(reset: true);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 400) {
      if (!_isLoadingMore && !_isInitialLoading && _hasMore) {
        _loadPage();
      }
    }
  }

  // ── pagination ────────────────────────────────────────────────────────────

  Query<Map<String, dynamic>> _baseQuery() {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection('reports')
        .orderBy('createdAt', descending: true);
    if (_filterStatus != 'all') {
      q = q.where('status', isEqualTo: _filterStatus);
    }
    return q;
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (!reset && (_isLoadingMore || !_hasMore)) return;

    if (reset) {
      setState(() {
        _docIds.clear();
        _docData.clear();
        _lastDoc = null;
        _hasMore = true;
        _isInitialLoading = true;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      var q = _baseQuery().limit(_pageSize);
      if (!reset && _lastDoc != null) {
        q = q.startAfterDocument(_lastDoc!);
      }
      final snap = await q.get();
      setState(() {
        for (final doc in snap.docs) {
          if (!_docIds.contains(doc.id)) _docIds.add(doc.id);
          _docData[doc.id] = doc.data();
        }
        if (snap.docs.isNotEmpty) _lastDoc = snap.docs.last;
        _hasMore          = snap.docs.length >= _pageSize;
        _isInitialLoading = false;
        _isLoadingMore    = false;
      });
    } catch (_) {
      setState(() {
        _isInitialLoading = false;
        _isLoadingMore    = false;
      });
    }
  }

  /// Client-side search over the already-loaded page set.
  List<String> get _filteredIds {
    if (_searchQuery.isEmpty) return _docIds;
    final q = _searchQuery.toLowerCase();
    return _docIds.where((id) {
      final d = _docData[id]!;
      return (d['title']        ?? '').toString().toLowerCase().contains(q) ||
             (d['reporterName'] ?? '').toString().toLowerCase().contains(q) ||
             (d['category']     ?? '').toString().toLowerCase().contains(q) ||
             (d['subCategory']  ?? '').toString().toLowerCase().contains(q) ||
             (d['address']      ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _showAssignDinasDialog(String id, Map<String, dynamic> data) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String? selected = data['dinasTerkait'] as String?;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            const Icon(LucideIcons.building2, size: 18, color: _blue),
            const SizedBox(width: 8),
            const Text('Teruskan ke Dinas'),
          ]),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: _dinasList
                  .map((dinas) => RadioListTile<String>(
                        value: dinas,
                        groupValue: selected,
                        title: Text(dinas, style: const TextStyle(fontSize: 13)),
                        activeColor: _blue,
                        onChanged: (v) => setSt(() => selected = v),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed:
                  selected == null ? null : () => Navigator.pop(ctx, selected),
              child: const Text('Teruskan'),
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;
    setState(() => _isUpdating = true);
    try {
      final update = <String, dynamic>{
        'dinasTerkait': result,
        'assignedAt':   FieldValue.serverTimestamp(),
        'updatedAt':    FieldValue.serverTimestamp(),
      };
      if ((data['status'] as String?) == 'Menunggu') {
        update['status']      = 'Diproses';
        update['processedAt'] = FieldValue.serverTimestamp();
      }
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(id)
          .update(update);

      final reporterUserId = data['userId'] as String? ?? '';
      if (reporterUserId.isNotEmpty) {
        await NotificationService.writeNotification(
          userId:   reporterUserId,
          title:    '\u2699\ufe0f Laporan Diteruskan',
          body:     'Laporan "${data['title'] ?? ''}" diteruskan ke $result',
          type:     'report_status',
          reportId: id,
        );
      }

      if (mounted) {
        setState(() {
          _isUpdating = false;
          if (_docData.containsKey(id)) {
            _docData[id]!['dinasTerkait'] = result;
            if (_docData[id]!['status'] == 'Menunggu') {
              _docData[id]!['status']      = 'Diproses';
              _docData[id]!['processedAt'] = Timestamp.now();
            }
          }
        });
        _snack('Laporan diteruskan ke $result', _blue);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        _snack('Gagal: $e', _red);
      }
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  Color _statusColor(String? s) {
    switch (s) {
      case 'Selesai':  return _green;
      case 'Diproses': return _amber;
      case 'Dihapus':  return _red;
      default:         return _blue;
    }
  }

  IconData _statusIcon(String? s) {
    switch (s) {
      case 'Selesai':  return LucideIcons.checkCircle2;
      case 'Diproses': return LucideIcons.clock;
      case 'Dihapus':  return LucideIcons.trash2;
      default:         return LucideIcons.alertCircle;
    }
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

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _pickAndUploadCompletionPhoto(String id) async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
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
        if (mounted) {
          setState(() {
            _docData[id]?['completionImageUrl'] = result['url'];
          });
          _snack('Bukti berhasil diunggah', _green);
        }
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _updateStatus(String id, String status,
      {String reporterUserId = '', String reportTitle = ''}) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    final Map<String, dynamic> update = {
      'status':    status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == 'Diproses') update['processedAt'] = FieldValue.serverTimestamp();
    if (status == 'Selesai')  update['completedAt']  = FieldValue.serverTimestamp();

    await FirebaseFirestore.instance.collection('reports').doc(id).update(update);

    if (status == 'Selesai' && reporterUserId.isNotEmpty) {
      await PoinHorasService.awardForResolved(reporterUserId, id);
    }
    if (reporterUserId.isNotEmpty) {
      await NotificationService.notifyReportStatus(
        userId: reporterUserId,
        reportTitle: reportTitle.isNotEmpty ? reportTitle : 'Laporan kamu',
        newStatus: status,
        reportId: id,
      );
    }

    if (mounted) {
      setState(() {
        _isUpdating = false;
        if (_docData.containsKey(id)) {
          _docData[id]!['status'] = status;
          if (status == 'Diproses') {
            _docData[id]!['processedAt'] = Timestamp.now();
          }
          if (status == 'Selesai') {
            _docData[id]!['completedAt'] = Timestamp.now();
          }
          // Remove from visible list if filter no longer matches
          if (_filterStatus != 'all' && _filterStatus != status) {
            _docIds.remove(id);
            _docData.remove(id);
          }
        }
      });
      final extra = status == 'Selesai' && reporterUserId.isNotEmpty
          ? ' (+${PoinHorasService.poinLaporanSelesai} Poin Horas ke pelapor)'
          : '';
      _snack('Status diubah ke $status$extra', _statusColor(status));
    }
  }

  void _showDeleteDialog(String id, String reporterUserId,
      {String reportTitle = ''}) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(LucideIcons.trash2, size: 18, color: _red),
          const SizedBox(width: 8),
          const Text('Hapus Laporan'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Berikan alasan penghapusan (spam / tidak valid / dll):',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(
                hintText: 'Contoh: Laporan duplikat / Tidak ada bukti...',
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF374151)
                    : const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _red.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(LucideIcons.alertTriangle, size: 14, color: _red),
                const SizedBox(width: 6),
                Text(
                  'Pelapor akan kena -${-PoinHorasService.poinSpamPenalty} Poin Horas',
                  style: const TextStyle(
                      fontSize: 11, color: _red, fontWeight: FontWeight.w600),
                ),
              ]),
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
              final reason = reasonCtrl.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx);
              _deleteReport(id, reporterUserId, reason,
                  reportTitle: reportTitle);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReport(
      String id, String reporterUserId, String reason,
      {String reportTitle = ''}) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    await FirebaseFirestore.instance.collection('reports').doc(id).update({
      'status':       'Dihapus',
      'deleteReason': reason,
      'deletedAt':    FieldValue.serverTimestamp(),
      'isActive':     false,
      'updatedAt':    FieldValue.serverTimestamp(),
    });

    if (reporterUserId.isNotEmpty) {
      await PoinHorasService.penalizeForSpam(reporterUserId, id);
      await NotificationService.notifyReportStatus(
        userId: reporterUserId,
        reportTitle: reportTitle.isNotEmpty ? reportTitle : 'Laporan kamu',
        newStatus: 'Dihapus',
        reportId: id,
      );
    }

    if (mounted) {
      setState(() {
        _isUpdating = false;
        if (_docData.containsKey(id)) {
          if (_filterStatus != 'all' && _filterStatus != 'Dihapus') {
            _docIds.remove(id);
            _docData.remove(id);
          } else {
            _docData[id]!['status']       = 'Dihapus';
            _docData[id]!['deleteReason'] = reason;
            _docData[id]!['isActive']     = false;
            _docData[id]!['deletedAt']    = Timestamp.now();
          }
        }
      });
      _snack(
        'Laporan dihapus (${PoinHorasService.poinSpamPenalty} Poin Horas ke pelapor)',
        _red,
      );
    }
  }

  // ── build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
    final card   = isDark ? const Color(0xFF1F2937) : Colors.white;

    final visible = _filteredIds;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: card,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft,
              color: isDark ? Colors.white : const Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Kelola Laporan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF111827),
            )),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.refreshCw,
                size: 18,
                color: isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280)),
            onPressed: () => _loadPage(reset: true),
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Search + filter ─────────────────────────────────────────
          Container(
            color: card,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari judul, pelapor, kategori, alamat…',
                    hintStyle: TextStyle(
                      color: isDark
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF9CA3AF),
                    ),
                    prefixIcon: Icon(LucideIcons.search,
                        size: 18,
                        color: isDark
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF9CA3AF)),
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
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip('Semua',    'all',      LucideIcons.layoutGrid,   _blue,  isDark),
                      const SizedBox(width: 8),
                      _chip('Menunggu', 'Menunggu', LucideIcons.alertCircle,  _blue,  isDark),
                      const SizedBox(width: 8),
                      _chip('Diproses', 'Diproses', LucideIcons.clock,        _amber, isDark),
                      const SizedBox(width: 8),
                      _chip('Selesai',  'Selesai',  LucideIcons.checkCircle2, _green, isDark),
                      const SizedBox(width: 8),
                      _chip('Dihapus',  'Dihapus',  LucideIcons.trash2,       _red,   isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1,
              color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
          // ── Summary bar ─────────────────────────────────────────────
          _summaryBar(isDark),
          Divider(height: 1,
              color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
          // ── List ────────────────────────────────────────────────────
          Expanded(
            child: _isInitialLoading
                ? Center(child: CircularProgressIndicator(color: _green))
                : visible.isEmpty
                    ? _emptyState(isDark)
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: visible.length + (_hasMore ? 1 : 0),
                        itemBuilder: (ctx, i) {
                          if (i == visible.length) {
                            return _loadMoreWidget(isDark);
                          }
                          final id   = visible[i];
                          final data = _docData[id]!;
                          return _reportCard(id, data, isDark, card);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // ── Summary bar ───────────────────────────────────────────────────────────

  Widget _summaryBar(bool isDark) {
    final all      = _docData.values;
    final menunggu = all.where((d) => d['status'] == 'Menunggu').length;
    final diproses = all.where((d) => d['status'] == 'Diproses').length;
    final selesai  = all.where((d) => d['status'] == 'Selesai').length;
    final dihapus  = all.where((d) => d['status'] == 'Dihapus').length;

    return Container(
      color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _pill('Menunggu', menunggu.toString(), _blue,  isDark),
          const SizedBox(width: 6),
          _pill('Proses',   diproses.toString(), _amber, isDark),
          const SizedBox(width: 6),
          _pill('Selesai',  selesai.toString(),  _green, isDark),
          const SizedBox(width: 6),
          _pill('Hapus',    dihapus.toString(),  _red,   isDark),
          const Spacer(),
          if (_hasMore)
            Text(
              '${_docData.length} dimuat',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? const Color(0xFF6B7280)
                    : const Color(0xFF9CA3AF),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pill(String label, String value, Color color, bool isDark) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: RichText(
          text: TextSpan(children: [
            TextSpan(
              text: value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 12),
            ),
            TextSpan(
              text: ' $label',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF6B7280),
              ),
            ),
          ]),
        ),
      );

  Widget _loadMoreWidget(bool isDark) {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: GestureDetector(
          onTap: _loadPage,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.chevronsDown, size: 16, color: _blue),
                const SizedBox(width: 6),
                Text('Muat Lebih Banyak',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _blue)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── filter chip ─────────────────────────────────────────────────────────────

  Widget _chip(String label, String value, IconData icon, Color color, bool isDark) {
    final active = _filterStatus == value;
    return GestureDetector(
      onTap: () {
        if (_filterStatus == value) return;
        setState(() => _filterStatus = value);
        _loadPage(reset: true);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color : (isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13,
                color: active ? Colors.white
                    : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280))),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white
                      : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                )),
          ],
        ),
      ),
    );
  }

  // ── report card ─────────────────────────────────────────────────────────────

  Widget _reportCard(String id, Map<String, dynamic> data, bool isDark, Color card) {
    final status         = data['status'] as String? ?? 'Menunggu';
    final sc             = _statusColor(status);
    final subCat         = (data['subCategory']  ?? '') as String;
    final category       = (data['category']      ?? '') as String;
    final address        = (data['address']        ?? '') as String;
    final reporter       = (data['reporterName']   ?? 'Anonymous') as String;
    final reporterUserId = (data['userId']          ?? '') as String;
    final reportTitle    = (data['title']           ?? '') as String;
    final imageUrl       = data['imageUrl'] as String?;
    final deleteReason   = data['deleteReason'] as String?;
    final upvotes        = (data['upvotes'] ?? 0) as num;
    final dinasTerkait   = data['dinasTerkait'] as String?;
    final border         = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final textMuted      = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

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
          // ── Header row ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_statusIcon(status), size: 18, color: sc),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] ?? 'Tanpa Judul',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      if (subCat.isNotEmpty || category.isNotEmpty)
                        Text(
                          subCat.isNotEmpty ? '$category · $subCat' : category,
                          style: TextStyle(fontSize: 11, color: sc, fontWeight: FontWeight.w500),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status badge + upvotes
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: sc.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: sc.withValues(alpha: 0.3)),
                      ),
                      child: Text(status,
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700, color: sc)),
                    ),
                    if (upvotes > 0) ...[  
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(LucideIcons.thumbsUp, size: 11, color: textMuted),
                        const SizedBox(width: 3),
                        Text(upvotes.toString(),
                            style: TextStyle(fontSize: 11, color: textMuted,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // ── Image (lazy-loaded) ───────────────────────────────────
          if (imageUrl != null && imageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 140,
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFE5E7EB),
                    child: Center(
                      child: Icon(LucideIcons.image,
                          size: 28,
                          color: isDark
                              ? const Color(0xFF6B7280)
                              : const Color(0xFF9CA3AF)),
                    ),
                  ),
                  errorWidget: (context, url, err) => Container(
                    height: 48,
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFF3F4F6),
                    child: Center(
                      child: Icon(LucideIcons.imageOff,
                          size: 18,
                          color: isDark
                              ? const Color(0xFF6B7280)
                              : const Color(0xFF9CA3AF)),
                    ),
                  ),
                ),
              ),
            ),

          // ── Meta info ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data['description'] != null &&
                    (data['description'] as String).isNotEmpty)
                  Text(
                    data['description'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: textMuted, height: 1.4),
                  ),
                const SizedBox(height: 8),
                _metaRow(LucideIcons.mapPin, address.isNotEmpty ? address : '-', textMuted),
                const SizedBox(height: 4),
                _metaRow(LucideIcons.user, reporter, textMuted),
                const SizedBox(height: 4),
                _metaRow(LucideIcons.calendar,
                    _formatTs(data['reportedAt'] ?? data['createdAt']), textMuted),
                if (dinasTerkait != null && dinasTerkait.isNotEmpty) ...[  
                  const SizedBox(height: 4),
                  _metaRow(LucideIcons.building2, dinasTerkait, _blue),
                ],
              ],
            ),
          ),

          // ── Timeline mini ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Progress dots ──────────────────────────
                  Row(
                    children: [
                      _dot(active: true, color: _green),
                      _connector(active: status == 'Diproses' || status == 'Selesai' || status == 'Dihapus'),
                      _dot(
                        active: status == 'Diproses' || status == 'Selesai' || status == 'Dihapus',
                        color: status == 'Dihapus' ? _red : _amber,
                      ),
                      _connector(active: status == 'Selesai' || status == 'Dihapus'),
                      _dot(
                        active: status == 'Selesai' || status == 'Dihapus',
                        color: status == 'Dihapus' ? _red : _green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // ── Labels + timestamps ────────────────────
                  Row(
                    children: [
                      _tsCol('Dilaporkan',
                          data['reportedAt'] ?? data['createdAt'], textMuted),
                      _tsCol('Diproses', data['processedAt'], textMuted),
                      _tsCol(
                        status == 'Dihapus' ? 'Dihapus' : 'Selesai',
                        status == 'Dihapus' ? data['deletedAt'] : data['completedAt'],
                        textMuted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Completion proof photo ────────────────────────
          if (status == 'Selesai')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: data['completionImageUrl'] != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.camera, size: 12, color: _green),
                            const SizedBox(width: 5),
                            Text('Bukti Penyelesaian',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _green)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: data['completionImageUrl'],
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 120,
                              color: isDark
                                  ? const Color(0xFF374151)
                                  : const Color(0xFFE5E7EB),
                            ),
                            errorWidget: (context, url, err) => const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    )
                  : GestureDetector(
                      onTap: _isUpdating ? null : () => _pickAndUploadCompletionPhoto(id),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _green.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.camera, size: 14, color: _green),
                            const SizedBox(width: 6),
                            Text('Upload Bukti Selesai',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _green)),
                          ],
                        ),
                      ),
                    ),
            ),

          // ── Delete reason (only when Dihapus) ──────────────────
          if (status == 'Dihapus' && deleteReason != null && deleteReason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _red.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _red.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.alertTriangle,
                        size: 13, color: _red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Alasan Penghapusan',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _red)),
                          const SizedBox(height: 2),
                          Text(deleteReason,
                              style: TextStyle(
                                  fontSize: 11, color: textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Action buttons ────────────────────────────────────────
          if (status != 'Dihapus')
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                if (status != 'Diproses' && status != 'Selesai')
                  Expanded(
                    child: _actionBtn(
                      label: 'Proses',
                      icon: LucideIcons.clock,
                      color: _amber,
                      onTap: () => _updateStatus(id, 'Diproses',
                          reporterUserId: reporterUserId,
                          reportTitle: reportTitle),
                    ),
                  ),
                if (status != 'Diproses' && status != 'Selesai')
                  const SizedBox(width: 8),
                if (status != 'Selesai')
                  Expanded(
                    child: _actionBtn(
                      label: 'Selesai',
                      icon: LucideIcons.checkCircle2,
                      color: _green,
                      onTap: () => _updateStatus(id, 'Selesai',
                          reporterUserId: reporterUserId,
                          reportTitle: reportTitle),
                    ),
                  ),
                if (status != 'Selesai') const SizedBox(width: 8),
                // Hapus button (always available unless already done)
                _actionBtn(
                  label: 'Hapus',
                  icon: LucideIcons.trash2,
                  color: _red,
                  onTap: () => _showDeleteDialog(id, reporterUserId, reportTitle: reportTitle),
                ),
                if (status == 'Selesai')
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.checkCircle2,
                              size: 14, color: _green),
                          const SizedBox(width: 6),
                          const Text('Laporan Selesai',
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
          ),

          // ── Assign Dinas row ─────────────────────────────────────
          if (status != 'Dihapus' && status != 'Selesai')
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: GestureDetector(
              onTap: _isUpdating
                  ? null
                  : () => _showAssignDinasDialog(id, data),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _blue.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.building2, size: 13, color: _blue),
                    const SizedBox(width: 6),
                    Text(
                      dinasTerkait != null && dinasTerkait.isNotEmpty
                          ? 'Pindah Dinas: $dinasTerkait'
                          : 'Teruskan ke Dinas',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _blue),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot({required bool active, required Color color}) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? color : Colors.transparent,
          border: Border.all(
            color: active ? color : Colors.grey.withValues(alpha: 0.35),
            width: 2,
          ),
        ),
      );

  Widget _connector({required bool active}) => Expanded(
        child: Container(
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            color: active ? _green.withValues(alpha: 0.6) : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
      );

  Widget _tsCol(String label, dynamic ts, Color muted) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700, color: muted)),
            const SizedBox(height: 2),
            Text(
              _formatTs(ts),
              style: TextStyle(fontSize: 9, color: muted),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );

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
                      fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ),
      );

  Widget _emptyState(bool isDark) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.clipboardList,
                size: 48,
                color: isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB)),
            const SizedBox(height: 12),
            Text('Tidak ada laporan',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                )),
          ],
        ),
      );
}
