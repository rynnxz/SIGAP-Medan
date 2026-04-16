import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/cloudinary_service.dart';
import '../services/poin_horas_service.dart';
import '../components/level_up_modal.dart';

class ReportFormScreen extends StatefulWidget {
  final String category;

  const ReportFormScreen({
    super.key,
    required this.category,
  });

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  bool _isLoading = false;
  bool _hasImage = false;
  File? _selectedImage;
  String? _cloudinaryImageUrl;
  bool _isUploadingImage = false;
  double? _latitude;
  double? _longitude;
  String _address = 'Mengambil lokasi...';
  bool _isFetchingLocation = true;
  String? _selectedSubCategory;

  final TextEditingController _descController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinary = CloudinaryService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const _green = Color(0xFF10B981);
  static const _red = Color(0xFFEF4444);

  static const Map<String, List<String>> _subCategories = {
    'Lingkungan & Bencana': [
      'Sampah menumpuk',
      'Banjir / genangan air',
      'Pohon tumbang',
      'Longsor',
      'Pencemaran air / tanah',
      'Kebakaran',
    ],
    'Transportasi & Mobilitas': [
      'Lampu lalu lintas rusak',
      'Rambu jalan rusak / hilang',
      'Jalan berlubang',
      'Jembatan rusak',
      'Kemacetan kronis',
      'Trotoar rusak',
    ],
    'Layanan Publik': [
      'Fasilitas umum rusak',
      'Vandalisme',
      'Lampu jalan mati',
      'Drainase tersumbat',
      'Toilet umum rusak',
      'Taman tidak terawat',
    ],
    'Ketertiban Sosial': [
      'Parkir liar',
      'Trotoar beralih fungsi',
      'Pedagang kaki lima liar',
      'Kebisingan',
      'Bangunan liar',
      'Penyalahgunaan fasilitas publik',
    ],
  };

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _descController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _address = 'Layanan lokasi tidak aktif';
          _isFetchingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _address = 'Izin lokasi ditolak';
          _isFetchingLocation = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      final p = placemarks.isNotEmpty ? placemarks.first : null;

      if (mounted) {
        setState(() {
          _latitude = pos.latitude;
          _longitude = pos.longitude;
          _address = [
            p?.street,
            p?.subLocality,
            p?.locality,
          ].where((s) => s != null && s.isNotEmpty).join(', ');
          _isFetchingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _address = 'Gagal mengambil lokasi';
          _isFetchingLocation = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _hasImage = true;
        });
        await _uploadToCloudinary();
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error: $e', _red);
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.camera, color: _green),
                ),
                title: const Text('Ambil Foto',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Gunakan kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.image, color: Colors.blue),
                ),
                title: const Text('Pilih dari Galeri',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Dari penyimpanan'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadToCloudinary() async {
    if (_selectedImage == null) return;
    setState(() => _isUploadingImage = true);
    try {
      final result = await _cloudinary.uploadReportPhoto(imageFile: _selectedImage!);
      if (mounted) {
        setState(() => _isUploadingImage = false);
        if (result['success']) {
          setState(() => _cloudinaryImageUrl = result['url']);
          _showSnack('Foto berhasil diunggah!', _green);
        } else {
          _showSnack('Upload gagal: ${result['error']}', _red);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        _showSnack('Error: $e', _red);
      }
    }
  }

  Future<void> _submitReport() async {
    if (_isLoading || _isUploadingImage) return;

    if (!_hasImage || _cloudinaryImageUrl == null) {
      _showSnack('Foto bukti wajib diambil', _red);
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      _showSnack('Judul tidak boleh kosong', _red);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Not authenticated');

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      final reportRef = await _firestore.collection('reports').add({
        'title': _titleController.text.trim(),
        'category': widget.category,
        'description': _descController.text.trim(),
        'imageUrl': _cloudinaryImageUrl,
        'subCategory': _selectedSubCategory ?? '',
        'latitude': _latitude ?? 0,
        'longitude': _longitude ?? 0,
        'address': _address,
        'status': 'Menunggu',
        'upvotes': 0,
        'upvotedBy': [],
        'reporterName': userData?['name'] ?? 'Anonymous',
        'userId': userId,
        'reportedAt': Timestamp.now(),
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      await _firestore.collection('users').doc(userId).update({
        'totalReports': FieldValue.increment(1),
      });
      final newLevel = await PoinHorasService.awardForSubmit(userId, reportRef.id);

      if (mounted) {
        setState(() => _isLoading = false);
        if (newLevel != null) {
          await LevelUpModal.show(context, newLevel);
        }
        if (mounted) Navigator.pop(context);
        _showSnack('Laporan terkirim! +${PoinHorasService.poinSubmitLaporan} Poin Horas 🎉', _green);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack('Error: $e', _red);
      }
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  IconData _categoryIcon() {
    switch (widget.category) {
      case 'Lingkungan & Bencana':
        return LucideIcons.leaf;
      case 'Transportasi & Mobilitas':
        return LucideIcons.car;
      case 'Layanan Publik':
        return LucideIcons.building2;
      case 'Ketertiban Sosial':
        return LucideIcons.shieldAlert;
      default:
        return LucideIcons.alertCircle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6);
    final cardBg = isDark ? const Color(0xFF1F2937) : Colors.white;
    final border = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textMuted = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Category badge ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _green.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_categoryIcon(), size: 14, color: _green),
                  const SizedBox(width: 6),
                  Text(
                    widget.category,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Photo section ────────────────────────────────────────
            _SectionLabel(label: 'Foto Bukti', muted: textMuted),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _isUploadingImage ? null : _showImageSourceSheet,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _cloudinaryImageUrl != null
                        ? _green
                        : _selectedImage != null
                            ? Colors.orange
                            : border,
                    width: _cloudinaryImageUrl != null ? 2 : 1,
                  ),
                ),
                child: _isUploadingImage
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: _green,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text('Mengunggah foto...',
                              style: TextStyle(fontSize: 13, color: textMuted)),
                        ],
                      )
                    : _selectedImage != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child:
                                    Image.file(_selectedImage!, fit: BoxFit.cover),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: _showImageSourceSheet,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.refreshCw,
                                            size: 12, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text('Ganti',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (_cloudinaryImageUrl != null)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _green,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.checkCircle2,
                                            size: 11, color: Colors.white),
                                        SizedBox(width: 3),
                                        Text('Terunggah',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _green.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(LucideIcons.imagePlus,
                                    size: 32, color: _green),
                              ),
                              const SizedBox(height: 10),
                              Text('Tambahkan Foto Bukti',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary)),
                              const SizedBox(height: 4),
                              Text('Kamera atau Galeri',
                                  style: TextStyle(
                                      fontSize: 12, color: textMuted)),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Location card ────────────────────────────────────────
            _SectionLabel(label: 'Lokasi', muted: textMuted),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: _isFetchingLocation
                  ? Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _green),
                        ),
                        const SizedBox(width: 10),
                        Text('Mengambil lokasi...',
                            style: TextStyle(fontSize: 13, color: textMuted)),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(LucideIcons.mapPin,
                                size: 16, color: _green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _address,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: textPrimary,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            GestureDetector(
                              onTap: _fetchLocation,
                              child: const Icon(LucideIcons.refreshCw,
                                  size: 14, color: _green),
                            ),
                          ],
                        ),
                        if (_latitude != null && _longitude != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF111827)
                                  : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: border),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.crosshair,
                                    size: 13, color: textMuted),
                                const SizedBox(width: 6),
                                Text(
                                  'Lat: ${_latitude!.toStringAsFixed(6)}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: textMuted,
                                      fontFamily: 'monospace'),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Lng: ${_longitude!.toStringAsFixed(6)}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: textMuted,
                                      fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 20),

            // ── Sub-category picker ───────────────────────────────────
            _SectionLabel(label: 'Jenis Masalah', muted: textMuted),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_subCategories[widget.category] ?? []).map((sub) {
                final selected = _selectedSubCategory == sub;
                return GestureDetector(
                  onTap: () => setState(() =>
                      _selectedSubCategory = selected ? null : sub),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? _green
                          : cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? _green : border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      sub,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? Colors.white
                            : textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Form fields ──────────────────────────────────────────
            _SectionLabel(label: 'Detail Laporan', muted: textMuted),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: Column(
                children: [
                  _StyledField(
                    controller: _titleController,
                    hint: 'Judul Laporan',
                    icon: LucideIcons.fileText,
                    isDark: isDark,
                    textColor: textPrimary,
                    iconColor: textMuted,
                  ),
                  Divider(height: 1, color: border),
                  _StyledField(
                    controller: _descController,
                    hint: 'Deskripsi kejadian...',
                    icon: LucideIcons.alignLeft,
                    isDark: isDark,
                    textColor: textPrimary,
                    iconColor: textMuted,
                    maxLines: 5,
                    minLines: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Submit button ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_isLoading || _isUploadingImage) ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _green.withValues(alpha: 0.4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.send, size: 17),
                          SizedBox(width: 8),
                          Text(
                            'Kirim Laporan',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.muted});
  final String label;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: muted,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _StyledField extends StatelessWidget {
  const _StyledField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.isDark,
    required this.textColor,
    required this.iconColor,
    this.maxLines = 1,
    this.minLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isDark;
  final Color textColor;
  final Color iconColor;
  final int maxLines;
  final int minLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              minLines: minLines,
              style: TextStyle(fontSize: 14, color: textColor),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: iconColor, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
