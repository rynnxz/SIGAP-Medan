import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/cloudinary_service.dart';

// ── Main Screen ───────────────────────────────────────────────────────────────

class AdminDestinationsScreen extends StatefulWidget {
  const AdminDestinationsScreen({super.key});

  @override
  State<AdminDestinationsScreen> createState() =>
      _AdminDestinationsScreenState();
}

class _AdminDestinationsScreenState extends State<AdminDestinationsScreen> {
  static const _green  = Color(0xFF10B981);
  static const _amber  = Color(0xFFF59E0B);
  static const _red    = Color(0xFFEF4444);
  static const _blue   = Color(0xFF3B82F6);
  static const _purple = Color(0xFF8B5CF6);
  static const _orange = Color(0xFFF97316);

  static const _cats = [
    'Semua', 'Hiburan', 'Sejarah', 'Kuliner',
    'Tempat Nongkrong', 'Wisata', 'Budaya', 'Alam',
  ];

  // ── pagination ──────────────────────────────────────────────────────────────
  static const int _pageSize = 8;
  final List<String> _docIds = [];
  final Map<String, Map<String, dynamic>> _docData = {};
  DocumentSnapshot? _lastDoc;
  bool _hasMore          = true;
  bool _isInitialLoading = true;
  bool _isLoadingMore    = false;
  bool _isBusy           = false;

  String _filterCat   = 'Semua';
  String _searchQuery = '';

  late final ScrollController _scrollCtrl;

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
      if (!_isLoadingMore && !_isInitialLoading && _hasMore) _loadPage();
    }
  }

  Query<Map<String, dynamic>> _baseQuery() {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection('destinations')
        .orderBy('createdAt', descending: true);
    if (_filterCat != 'Semua') {
      q = q.where('category', isEqualTo: _filterCat);
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
      if (!reset && _lastDoc != null) q = q.startAfterDocument(_lastDoc!);
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

  List<String> get _filteredIds {
    if (_searchQuery.isEmpty) return _docIds;
    final q = _searchQuery.toLowerCase();
    return _docIds.where((id) {
      final d = _docData[id]!;
      return (d['name']     ?? '').toString().toLowerCase().contains(q) ||
             (d['city']     ?? '').toString().toLowerCase().contains(q) ||
             (d['address']  ?? '').toString().toLowerCase().contains(q) ||
             (d['category'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  // ── helpers ─────────────────────────────────────────────────────────────────

  Color _catColor(String? c) {
    switch (c) {
      case 'Hiburan':          return _amber;
      case 'Sejarah':          return _blue;
      case 'Kuliner':          return _orange;
      case 'Tempat Nongkrong': return _purple;
      case 'Wisata':           return _green;
      default:                 return _blue;
    }
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

  // ── actions ─────────────────────────────────────────────────────────────────

  Future<void> _toggleActive(String id) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    final current = _docData[id]?['isActive'] == true;
    await FirebaseFirestore.instance
        .collection('destinations')
        .doc(id)
        .update({'isActive': !current, 'updatedAt': FieldValue.serverTimestamp()});
    if (mounted) {
      setState(() {
        _docData[id]?['isActive'] = !current;
        _isBusy = false;
      });
      _snack(
        current ? 'Destinasi dinonaktifkan' : 'Destinasi diaktifkan',
        current ? _amber : _green,
      );
    }
  }

  Future<void> _deleteDestination(String id, String name) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(LucideIcons.trash2, size: 18, color: _red),
          const SizedBox(width: 8),
          const Text('Hapus Destinasi'),
        ]),
        content: Text(
          'Hapus "$name"? Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
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
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isBusy = true);
    await FirebaseFirestore.instance
        .collection('destinations')
        .doc(id)
        .delete();
    if (mounted) {
      setState(() {
        _docIds.remove(id);
        _docData.remove(id);
        _isBusy = false;
      });
      _snack('Destinasi "$name" dihapus', _red);
    }
  }

  void _showForm({String? id, Map<String, dynamic>? existing}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DestinationForm(
        isDark: isDark,
        existing: existing,
        docId: id,
        onSaved: (docId, data) {
          setState(() {
            if (id == null) _docIds.insert(0, docId);
            _docData[docId] = data;
          });
          _snack(
            id == null
                ? 'Destinasi berhasil ditambahkan'
                : 'Destinasi berhasil diperbarui',
            _green,
          );
        },
      ),
    );
  }

  // ── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
    final card    = isDark ? const Color(0xFF1F2937) : Colors.white;
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
        title: Text('Kelola Destinasi',
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
              color:
                  isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(LucideIcons.plus, size: 18),
        label: const Text('Tambah',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: _green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ── Search + filter ────────────────────────────────────────
          Container(
            color: card,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari nama, kota, alamat…',
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
                    children: _cats.asMap().entries.map((e) {
                      final isLast = e.key == _cats.length - 1;
                      return Padding(
                        padding: EdgeInsets.only(right: isLast ? 0 : 8),
                        child: _chip(e.value, isDark),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1,
              color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
          // ── Summary bar ────────────────────────────────────────────
          _summaryBar(isDark),
          Divider(height: 1,
              color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
          // ── List ───────────────────────────────────────────────────
          Expanded(
            child: _isInitialLoading
                ? Center(child: CircularProgressIndicator(color: _green))
                : visible.isEmpty
                    ? _emptyState(isDark)
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                        itemCount: visible.length + (_hasMore ? 1 : 0),
                        itemBuilder: (ctx, i) {
                          if (i == visible.length) {
                            return _loadMoreWidget(isDark);
                          }
                          final id = visible[i];
                          return _destinationCard(
                              id, _docData[id]!, isDark, card);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // ── Summary bar ──────────────────────────────────────────────────────────────

  Widget _summaryBar(bool isDark) {
    final all      = _docData.values;
    final active   = all.where((d) => d['isActive'] == true).length;
    final inactive = all.length - active;
    return Container(
      color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _pill('Aktif',    active.toString(),   _green, isDark),
          const SizedBox(width: 6),
          _pill('Nonaktif', inactive.toString(), _red,   isDark),
          const Spacer(),
          if (_hasMore)
            Text('${_docData.length} dimuat',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF9CA3AF),
                )),
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

  // ── Filter chip ──────────────────────────────────────────────────────────────

  Widget _chip(String cat, bool isDark) {
    final active = _filterCat == cat;
    final color  = cat == 'Semua' ? _blue : _catColor(cat);
    return GestureDetector(
      onTap: () {
        if (_filterCat == cat) return;
        setState(() => _filterCat = cat);
        _loadPage(reset: true);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? color
              : (isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? color : Colors.transparent, width: 1.5),
        ),
        child: Text(cat,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active
                  ? Colors.white
                  : (isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280)),
            )),
      ),
    );
  }

  // ── Destination card ─────────────────────────────────────────────────────────

  Widget _destinationCard(
      String id, Map<String, dynamic> data, bool isDark, Color card) {
    final name         = (data['name']         ?? 'Tanpa Nama') as String;
    final category     = (data['category']     ?? '') as String;
    final city         = (data['city']         ?? '') as String;
    final address      = (data['address']      ?? '') as String;
    final description  = (data['description']  ?? '') as String;
    final imageUrl     = (data['imageUrl']     ?? '') as String;
    final isActive     = data['isActive'] == true;
    final rating       = (data['rating']       ?? 0.0) as num;
    final reviews      = (data['reviews']      ?? 0) as num;
    final ticketPrice  = (data['ticketPrice']  ?? '') as String;
    final openingHours = (data['openingHours'] ?? '') as String;
    final favorites    = (data['favoritedBy'] as List?)?.length ?? 0;
    final catColor     = _catColor(category);
    final border       = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final textMuted    = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? border : _red.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cover image with badge overlay ──────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        height: 155,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => _imgPlaceholder(
                            isDark, LucideIcons.image, 155),
                        errorWidget: (context, url, err) => _imgPlaceholder(
                            isDark, LucideIcons.imageOff, 155),
                      )
                    : _imgPlaceholder(isDark, LucideIcons.mapPin, 155),
              ),
              // gradient overlay
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.5),
                          Colors.transparent
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                  top: 10, left: 10, child: _imgBadge(category, catColor)),
              Positioned(
                top: 10,
                right: 10,
                child: _imgBadge(
                  isActive ? 'Aktif' : 'Nonaktif',
                  isActive ? _green : _red,
                ),
              ),
              if (favorites > 0)
                Positioned(
                  bottom: 8, right: 12,
                  child: Row(children: [
                    const Icon(LucideIcons.heart,
                        size: 13, color: Colors.white),
                    const SizedBox(width: 3),
                    Text(favorites.toString(),
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
            ],
          ),

          // ── Info ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                // Rating + city row
                Row(
                  children: [
                    Icon(LucideIcons.star, size: 13, color: _amber),
                    const SizedBox(width: 3),
                    Text(rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                        )),
                    const SizedBox(width: 4),
                    Text('($reviews ulasan)',
                        style: TextStyle(fontSize: 11, color: textMuted)),
                    const Spacer(),
                    if (city.isNotEmpty) ...[
                      Icon(LucideIcons.mapPin, size: 12, color: textMuted),
                      const SizedBox(width: 3),
                      Text(city,
                          style: TextStyle(
                              fontSize: 12,
                              color: textMuted,
                              fontWeight: FontWeight.w500)),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                // Ticket + hours row
                Row(
                  children: [
                    if (ticketPrice.isNotEmpty) ...[
                      Icon(LucideIcons.tag, size: 12, color: _green),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(ticketPrice,
                            style: TextStyle(
                                fontSize: 11,
                                color: _green,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (openingHours.isNotEmpty) ...[
                      Icon(LucideIcons.clock, size: 12, color: textMuted),
                      const SizedBox(width: 3),
                      Text(openingHours,
                          style: TextStyle(fontSize: 11, color: textMuted)),
                    ],
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(description,
                      style: TextStyle(
                          fontSize: 12, color: textMuted, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
                if (address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(LucideIcons.mapPin, size: 11, color: textMuted),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(address,
                          style: TextStyle(fontSize: 11, color: textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ],
              ],
            ),
          ),

          // ── Action row ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    label: isActive ? 'Nonaktifkan' : 'Aktifkan',
                    icon: isActive ? LucideIcons.eyeOff : LucideIcons.eye,
                    color: isActive ? _amber : _green,
                    onTap: () => _toggleActive(id),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionBtn(
                    label: 'Edit',
                    icon: LucideIcons.pencil,
                    color: _blue,
                    onTap: () =>
                        _showForm(id: id, existing: Map.from(_docData[id]!)),
                  ),
                ),
                const SizedBox(width: 8),
                _actionBtn(
                  label: 'Hapus',
                  icon: LucideIcons.trash2,
                  color: _red,
                  onTap: () => _deleteDestination(id, name),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── small helpers ─────────────────────────────────────────────────────────────

  Widget _imgPlaceholder(bool isDark, IconData icon, double height) =>
      Container(
        height: height,
        width: double.infinity,
        color:
            isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        child: Center(
          child: Icon(icon,
              size: 32,
              color: isDark
                  ? const Color(0xFF6B7280)
                  : const Color(0xFF9CA3AF)),
        ),
      );

  Widget _imgBadge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      );

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: _isBusy ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
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

  Widget _emptyState(bool isDark) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.mapPin,
                size: 48,
                color: isDark
                    ? const Color(0xFF374151)
                    : const Color(0xFFD1D5DB)),
            const SizedBox(height: 12),
            Text('Tidak ada destinasi',
                style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF9CA3AF))),
          ],
        ),
      );
}

// ── Add / Edit Form ───────────────────────────────────────────────────────────

class _DestinationForm extends StatefulWidget {
  const _DestinationForm({
    required this.isDark,
    this.existing,
    this.docId,
    required this.onSaved,
  });

  final bool isDark;
  final Map<String, dynamic>? existing;
  final String? docId;
  final void Function(String docId, Map<String, dynamic> data) onSaved;

  @override
  State<_DestinationForm> createState() => _DestinationFormState();
}

class _DestinationFormState extends State<_DestinationForm> {
  static const _green = Color(0xFF10B981);
  static const _red   = Color(0xFFEF4444);

  static const _catList = [
    'Hiburan', 'Sejarah', 'Kuliner', 'Tempat Nongkrong',
    'Wisata', 'Budaya', 'Alam', 'Museum', 'Taman', 'Ruang Publik',
  ];

  final _formKey = GlobalKey<FormState>();
  bool _isSaving    = false;
  bool _isUploading = false;
  File? _pickedImage;

  late final TextEditingController _name;
  late final TextEditingController _city;
  late final TextEditingController _address;
  late final TextEditingController _description;
  late final TextEditingController _imageUrl;
  late final TextEditingController _ticketPrice;
  late final TextEditingController _openingHours;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  late String _category;
  late bool   _isActive;

  @override
  void initState() {
    super.initState();
    final d        = widget.existing;
    _name          = TextEditingController(text: d?['name']         ?? '');
    _city          = TextEditingController(text: d?['city']         ?? '');
    _address       = TextEditingController(text: d?['address']      ?? '');
    _description   = TextEditingController(text: d?['description']  ?? '');
    _imageUrl      = TextEditingController(text: d?['imageUrl']     ?? '');
    _ticketPrice   = TextEditingController(text: d?['ticketPrice']  ?? '');
    _openingHours  = TextEditingController(text: d?['openingHours'] ?? '');
    _latitude      = TextEditingController(
        text: d?['latitude']  != null ? d!['latitude'].toString()  : '');
    _longitude     = TextEditingController(
        text: d?['longitude'] != null ? d!['longitude'].toString() : '');
    final rawCat   = d?['category'] as String?;
    _category      = (rawCat != null && _catList.contains(rawCat))
        ? rawCat
        : _catList.first;
    _isActive      = d?['isActive'] ?? true;
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name, _city, _address, _description, _imageUrl,
      _ticketPrice, _openingHours, _latitude, _longitude,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      // Upload image to Cloudinary if a new file was picked
      if (_pickedImage != null) {
        setState(() => _isUploading = true);
        final result = await CloudinaryService()
            .uploadDestinationPhoto(imageFile: _pickedImage!);
        setState(() => _isUploading = false);
        if (result['success'] == true) {
          _imageUrl.text = result['url'] as String;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Gagal upload gambar: ${result['error']}'),
              backgroundColor: _red,
              behavior: SnackBarBehavior.floating,
            ));
          }
          setState(() => _isSaving = false);
          return;
        }
      }

      final Map<String, dynamic> data = {
        'name':         _name.text.trim(),
        'city':         _city.text.trim(),
        'address':      _address.text.trim(),
        'description':  _description.text.trim(),
        'imageUrl':     _imageUrl.text.trim(),
        'ticketPrice':  _ticketPrice.text.trim(),
        'openingHours': _openingHours.text.trim(),
        'latitude':     double.tryParse(_latitude.text.trim())  ?? 0.0,
        'longitude':    double.tryParse(_longitude.text.trim()) ?? 0.0,
        'category':     _category,
        'isActive':     _isActive,
        'updatedAt':    FieldValue.serverTimestamp(),
      };

      String docId;
      if (widget.docId == null) {
        data['createdAt']   = FieldValue.serverTimestamp();
        data['rating']      = 0.0;
        data['reviews']     = 0;
        data['favoritedBy'] = [];
        final ref = await FirebaseFirestore.instance
            .collection('destinations')
            .add(data);
        docId = ref.id;
      } else {
        docId = widget.docId!;
        await FirebaseFirestore.instance
            .collection('destinations')
            .doc(docId)
            .update(data);
        // preserve existing fields not touched by the form
        final existing = widget.existing ?? {};
        data['rating']      = existing['rating']      ?? 0.0;
        data['reviews']     = existing['reviews']     ?? 0;
        data['favoritedBy'] = existing['favoritedBy'] ?? [];
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved(docId, data);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = widget.isDark;
    final bg       = isDark ? const Color(0xFF1F2937) : Colors.white;
    final surface  = isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);
    final textCol  = isDark ? Colors.white : const Color(0xFF111827);
    final mutedCol = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final isEdit   = widget.docId != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF4B5563)
                        : const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
                child: Row(
                  children: [
                    Text(
                      isEdit ? 'Edit Destinasi' : 'Tambah Destinasi',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textCol),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(LucideIcons.x, color: mutedCol),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(
                  height: 1,
                  color: isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFE5E7EB)),
              // fields
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _field('Nama Destinasi', _name, textCol, surface, mutedCol,
                        required: true),
                    const SizedBox(height: 14),
                    // category
                    Text('Kategori',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: mutedCol)),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _category,
                          isExpanded: true,
                          dropdownColor: bg,
                          style: TextStyle(color: textCol, fontSize: 14),
                          items: _catList
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c,
                                        style: TextStyle(color: textCol)),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _category = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _field('Kota', _city, textCol, surface, mutedCol),
                    const SizedBox(height: 14),
                    _field('Alamat Lengkap', _address, textCol, surface,
                        mutedCol),
                    const SizedBox(height: 14),
                    _field('Deskripsi', _description, textCol, surface,
                        mutedCol, maxLines: 4),
                    const SizedBox(height: 14),
                    // ── Image picker ──────────────────────────────────────
                    Text('Gambar Destinasi',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: mutedCol)),
                    const SizedBox(height: 6),
                    _isUploading
                        ? Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                      color: _green),
                                  SizedBox(height: 8),
                                  Text('Mengupload gambar...'),
                                ],
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              height: 180,
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF4B5563)
                                      : const Color(0xFFD1D5DB),
                                  width: 1.5,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: _pickedImage != null
                                    ? Image.file(_pickedImage!,
                                        fit: BoxFit.cover,
                                        width: double.infinity)
                                    : _imageUrl.text.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: _imageUrl.text,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            errorWidget: (_, __, ___) =>
                                                _imagePlaceholder(mutedCol),
                                          )
                                        : _imagePlaceholder(mutedCol),
                              ),
                            ),
                          ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(LucideIcons.imagePlus, size: 15),
                            label: Text(
                              _pickedImage != null ||
                                      _imageUrl.text.isNotEmpty
                                  ? 'Ganti Gambar'
                                  : 'Pilih dari File',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _green,
                              side: const BorderSide(
                                  color: _green, width: 1),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        if (_pickedImage != null ||
                            _imageUrl.text.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => setState(() {
                              _pickedImage = null;
                              _imageUrl.text = '';
                            }),
                            icon: const Icon(LucideIcons.trash2, size: 15),
                            label: const Text('Hapus'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _red,
                              side: const BorderSide(
                                  color: _red, width: 1),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    _field('Harga Tiket', _ticketPrice, textCol, surface,
                        mutedCol,
                        hint: 'Contoh: Rp 50.000 - 150.000'),
                    const SizedBox(height: 14),
                    _field('Jam Buka', _openingHours, textCol, surface,
                        mutedCol,
                        hint: 'Contoh: 09:00 - 18:00'),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _field('Latitude', _latitude, textCol,
                              surface, mutedCol,
                              hint: '3.2687',
                              keyboardType: TextInputType.number),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field('Longitude', _longitude, textCol,
                              surface, mutedCol,
                              hint: '98.5552',
                              keyboardType: TextInputType.number),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // isActive toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.eye, size: 16, color: _green),
                          const SizedBox(width: 10),
                          Text('Status Aktif',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textCol)),
                          const Spacer(),
                          Switch(
                            value: _isActive,
                            onChanged: (v) => setState(() => _isActive = v),
                            activeThumbColor: _green,
                            activeTrackColor: _green.withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text(
                                isEdit
                                    ? 'Simpan Perubahan'
                                    : 'Tambah Destinasi',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder(Color mutedCol) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.imagePlus, size: 36, color: mutedCol),
          const SizedBox(height: 8),
          Text('Ketuk untuk pilih gambar',
              style: TextStyle(fontSize: 12, color: mutedCol)),
        ],
      );

  Widget _field(
    String label,
    TextEditingController ctrl,
    Color textCol,
    Color surface,
    Color mutedCol, {
    bool required = false,
    int maxLines = 1,
    String? hint,
    TextInputType? keyboardType,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: mutedCol),
              children: required
                  ? const [
                      TextSpan(
                          text: ' *',
                          style: TextStyle(color: _red))
                    ]
                  : [],
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: TextStyle(color: textCol, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: mutedCol, fontSize: 13),
              filled: true,
              fillColor: surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
            ),
            validator: required
                ? (v) => (v == null || v.trim().isEmpty)
                    ? '$label wajib diisi'
                    : null
                : null,
          ),
        ],
      );
}
