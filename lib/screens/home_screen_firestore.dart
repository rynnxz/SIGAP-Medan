import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/custom_bottom_nav.dart';
import '../services/notification_service.dart';
import '../components/onboarding_dialog.dart';
import '../components/report_category_modal.dart';
import 'jejak_kesawan_screen.dart';
import 'poin_horas_screen.dart';
import 'profile_screen.dart';
import 'report_detail_screen_firestore.dart';
import 'destination_detail_screen_firestore.dart';
import 'email_verification_screen.dart';
import 'sos_alert_screen.dart';

class HomeScreenFirestore extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  const HomeScreenFirestore({
    super.key,
    required this.onThemeChanged,
  });

  @override
  State<HomeScreenFirestore> createState() => _HomeScreenFirestoreState();
}

class _HomeScreenFirestoreState extends State<HomeScreenFirestore> {
  int _selectedIndex = 0;
  final MapController _mapController = MapController();
  final LatLng _medanCenter = const LatLng(3.5952, 98.6722);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _activeCategory;
  bool _showDestinations = true;
  bool _showReports = true;
  bool _showCompleted = false;
  LatLng? _currentLocation;
  bool _hasInitiallyMoved = false;
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<QuerySnapshot>? _sosSub;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final FocusNode _searchFocus = FocusNode();
  bool _emailVerified = true;

  @override
  void initState() {
    super.initState();
    _startLocationStream();
    _checkEmailVerificationOnce();
    _checkAdminAndListenSos();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) showOnboardingIfNeeded(context);
      });
    });
  }

  Future<void> _checkEmailVerificationOnce() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await user.reload();
    final refreshed = FirebaseAuth.instance.currentUser;
    final verified = refreshed?.emailVerified ?? true;

    if (mounted) setState(() => _emailVerified = verified);

    if (!verified) {
      final prefs = await SharedPreferences.getInstance();
      final key = 'email_verify_shown_${user.uid}';
      final alreadyShown = prefs.getBool(key) ?? false;

      if (!alreadyShown && mounted) {
        await prefs.setBool(key, true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showEmailVerificationPopup();
        });
      }
    }
  }

  void _showEmailVerificationPopup() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.mailWarning, color: Color(0xFFF59E0B), size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Verifikasi Email',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: const Text(
          'Email Anda belum diverifikasi. Verifikasi diperlukan sebelum dapat membuat laporan di SIGAP Medan.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Nanti', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EmailVerificationScreen(),
                ),
              );
              if (result == true && mounted) {
                setState(() => _emailVerified = true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Verifikasi Sekarang'),
          ),
        ],
      ),
    );
  }

  void _showActionSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? const Color(0xFF1F2937) : Colors.white;
    final textCol = isDark ? Colors.white : const Color(0xFF111827);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF4B5563)
                    : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('Pilih Aksi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textCol,
                )),
            const SizedBox(height: 20),
            // Lapor masalah
            _actionTile(
              context: ctx,
              icon: LucideIcons.fileWarning,
              iconColor: const Color(0xFF10B981),
              title: 'Laporkan Masalah',
              subtitle: 'Laporkan kejadian atau kondisi di sekitarmu',
              isDark: isDark,
              onTap: () {
                Navigator.pop(ctx);
                showReportCategorySheet(context);
              },
            ),
            const SizedBox(height: 12),
            // SOS darurat
            _actionTile(
              context: ctx,
              icon: LucideIcons.alertOctagon,
              iconColor: const Color(0xFFEF4444),
              title: 'Darurat SOS',
              subtitle: 'Kirim sinyal darurat dengan koordinat GPS',
              isDark: isDark,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(PageRouteBuilder(
                  opaque: false,
                  barrierColor: Colors.black54,
                  pageBuilder: (_, __, ___) => const SosAlertScreen(),
                  transitionsBuilder: (_, anim, __, child) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: anim, curve: Curves.easeOut)),
                    child: child,
                  ),
                  transitionDuration: const Duration(milliseconds: 320),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF374151)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                      )),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight,
                size: 16,
                color: isDark
                    ? const Color(0xFF6B7280)
                    : const Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  void _showVerificationRequiredDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.lock, color: Color(0xFFEF4444), size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Email Belum Diverifikasi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: const Text(
          'Kamu perlu memverifikasi email terlebih dahulu sebelum dapat membuat laporan.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EmailVerificationScreen(),
                ),
              );
              if (result == true && mounted) {
                setState(() => _emailVerified = true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Verifikasi Email'),
          ),
        ],
      ),
    );
  }

  Future<void> _startLocationStream() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) return;

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      if (mounted) {
        final loc = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _currentLocation = loc;
        });
        if (!_hasInitiallyMoved) {
          _hasInitiallyMoved = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _mapController.move(loc, 15);
          });
        }
      }
    });
  }

  Future<void> _checkAdminAndListenSos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (doc.data()?['accountType'] == 'admin') {
      _subscribeSosAlerts();
    }
  }

  void _subscribeSosAlerts() {
    final since = Timestamp.now();
    _sosSub = FirebaseFirestore.instance
        .collection('sos_notifications')
        .where('createdAt', isGreaterThan: since)
        .snapshots()
        .listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final d = change.doc.data() as Map<String, dynamic>;
          NotificationService.showSosNotification(
            alertId: change.doc.id,
            userName: d['userName'] as String? ?? 'Pengguna',
            category: d['category'] as String? ?? 'Darurat',
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _sosSub?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  static const _categories = [
    ('Lingkungan & Bencana',  LucideIcons.leaf,        Color(0xFF10B981)),
    ('Transportasi & Mobilitas', LucideIcons.car,      Color(0xFF3B82F6)),
    ('Layanan Publik',        LucideIcons.building2,   Color(0xFF8B5CF6)),
    ('Ketertiban Sosial',     LucideIcons.shieldAlert, Color(0xFFF59E0B)),
  ];

  static IconData _destinationIcon(String? category) {
    final cat = (category ?? '').toLowerCase();
    if (cat.contains('museum') || cat.contains('sejarah') || cat.contains('heritage') || cat.contains('monumen'))
      return LucideIcons.landmark;
    if (cat.contains('cafe') || cat.contains('kopi') || cat.contains('nongkrong') || cat.contains('kedai'))
      return LucideIcons.coffee;
    if (cat.contains('restoran') || cat.contains('makan') || cat.contains('kuliner') || cat.contains('food'))
      return LucideIcons.utensils;
    if (cat.contains('taman') || cat.contains('park') || cat.contains('kebun') || cat.contains('hutan'))
      return LucideIcons.trees;
    if (cat.contains('toko') || cat.contains('belanja') || cat.contains('mall') || cat.contains('pasar') || cat.contains('shop'))
      return LucideIcons.shoppingBag;
    if (cat.contains('pantai') || cat.contains('danau') || cat.contains('sungai') || cat.contains('air'))
      return LucideIcons.waves;
    if (cat.contains('hotel') || cat.contains('penginapan') || cat.contains('resort'))
      return LucideIcons.building;
    if (cat.contains('olahraga') || cat.contains('sport') || cat.contains('stadion'))
      return LucideIcons.trophy;
    if (cat.contains('seni') || cat.contains('galeri') || cat.contains('budaya') || cat.contains('art'))
      return LucideIcons.palette;
    if (cat.contains('religi') || cat.contains('masjid') || cat.contains('gereja') || cat.contains('pura'))
      return LucideIcons.church;
    return LucideIcons.mapPin;
  }

  static Color _categoryColor(String? cat) {
    for (final c in _categories) {
      if (c.$1 == cat) return c.$3;
    }
    return Colors.red;
  }

  static IconData _categoryIcon(String? cat) {
    for (final c in _categories) {
      if (c.$1 == cat) return c.$2;
    }
    return LucideIcons.alertCircle;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildMapScreen(),
      const JejakKesawanScreen(),
      const PoinHorasScreen(),
      ProfileScreen(
        currentTheme: ThemeMode.system,
        onThemeChanged: widget.onThemeChanged,
      ),
    ];

    const double navHeight      = 70.0;
    const double navBottomGap   = 16.0;
    final double systemBottom   = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: MediaQuery.of(context).padding.copyWith(
            bottom: systemBottom + navHeight + navBottomGap,
          ),
        ),
        child: Stack(
          children: [
            // ── main content (fills full screen) ────────────────────
            screens[_selectedIndex],

            // ── floating nav overlay ─────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: systemBottom + navBottomGap,
              child: CustomBottomNav(
                currentIndex: _selectedIndex,
                isEmailVerified: _emailVerified,
                onTap: (index) {
                  if (index == -1) {
                    if (!_emailVerified) {
                      _showVerificationRequiredDialog();
                    } else {
                      _showActionSheet();
                    }
                  } else {
                    setState(() => _selectedIndex = index);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _medanCenter,
            initialZoom: 13.0,
            minZoom: 9.0,
            cameraConstraint: CameraConstraint.containCenter(
              bounds: LatLngBounds(
                const LatLng(1.0, 97.5),
                const LatLng(5.5, 100.5),
              ),
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: isDark
                  ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                  : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),
            _buildCurrentLocationLayer(),
            if (_showDestinations) _buildDestinationMarkers(),
            if (_showReports) _buildReportMarkers(),
          ],
        ),
        // ── Top overlay (search bar + filter chips) ──────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 12,
          right: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8)],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cari laporan, kategori, jalan...',
                    hintStyle: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                    prefixIcon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF9CA3AF)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 16, color: Color(0xFF9CA3AF)),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _searchFocus.unfocus();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              // Category chips + layer toggles (hidden while searching)
              if (_searchQuery.isEmpty) ...
                [
                  const SizedBox(height: 8),
                  // ── Category chips (only when Laporan layer on) ─
                  if (_showReports) ...
                    [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'Semua',
                              icon: LucideIcons.layoutGrid,
                              color: const Color(0xFF6B7280),
                              active: _activeCategory == null,
                              isDark: isDark,
                              onTap: () => setState(() => _activeCategory = null),
                            ),
                            const SizedBox(width: 8),
                            ..._categories.map((c) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _FilterChip(
                                label: c.$1.split(' & ').first,
                                icon: c.$2,
                                color: c.$3,
                                active: _activeCategory == c.$1,
                                isDark: isDark,
                                onTap: () => setState(() =>
                                    _activeCategory = _activeCategory == c.$1
                                        ? null
                                        : c.$1),
                              ),
                            )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  // ── Layer toggles ──────────────────────────────
                  Row(
                    children: [
                      _LayerChip(
                        label: 'Wisata',
                        icon: LucideIcons.mapPin,
                        color: const Color(0xFF10B981),
                        active: _showDestinations,
                        isDark: isDark,
                        onTap: () => setState(() {
                          _showDestinations = !_showDestinations;
                        }),
                      ),
                      const SizedBox(width: 8),
                      _LayerChip(
                        label: 'Laporan',
                        icon: LucideIcons.alertCircle,
                        color: const Color(0xFFEF4444),
                        active: _showReports,
                        isDark: isDark,
                        onTap: () => setState(() {
                          _showReports = !_showReports;
                          if (!_showReports) _activeCategory = null;
                        }),
                      ),
                      const SizedBox(width: 8),
                      _LayerChip(
                        label: 'Selesai',
                        icon: LucideIcons.checkCircle,
                        color: const Color(0xFF10B981),
                        active: _showCompleted,
                        isDark: isDark,
                        onTap: () => setState(() => _showCompleted = !_showCompleted),
                      ),
                    ],
                  ),
                ],
            ],
          ),
        ),
        // ── Search results overlay ────────────────────────────────
        if (_searchQuery.isNotEmpty)
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 12,
            right: 12,
            bottom: 110,
            child: _SearchResultsPanel(
              query: _searchQuery,
              firestore: _firestore,
              isDark: isDark,
              onTap: (id, type) {
                _searchController.clear();
                setState(() => _searchQuery = '');
                _searchFocus.unfocus();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => type == 'destination'
                        ? DestinationDetailScreenFirestore(destinationId: id)
                        : ReportDetailScreenFirestore(reportId: id),
                  ),
                );
              },
            ),
          ),
        // ── Locate-me button ─────────────────────────────────────
        if (_currentLocation != null)
          Positioned(
            bottom: 110,
            left: 12,
            child: GestureDetector(
              onTap: () => _mapController.move(_currentLocation!, 15),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                  )],
                ),
                child: const Icon(LucideIcons.locateFixed, size: 22, color: Color(0xFF3B82F6)),
              ),
            ),
          ),
        // ── Legend ───────────────────────────────────────────────
        Positioned(
          bottom: 110,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _LegendItem(color: const Color(0xFF10B981), label: 'Destinasi'),
                const SizedBox(height: 4),
                _LegendItem(color: Colors.amber, label: 'Diproses'),
                const SizedBox(height: 4),
                _LegendItem(color: Colors.red, label: 'Menunggu'),
                if (_showCompleted) ...[const SizedBox(height: 4), _LegendItem(color: const Color(0xFF10B981), label: 'Selesai')],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationMarkers() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('destinations').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final markers = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['isActive'] != false;
        }).map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final lat = (data['latitude'] as num?)?.toDouble() ??
              double.tryParse(data['latitude']?.toString() ?? '0') ?? 0;
          final lng = (data['longitude'] as num?)?.toDouble() ??
              double.tryParse(data['longitude']?.toString() ?? '0') ?? 0;
          final category = data['category'] as String?;
          final icon = _destinationIcon(category);

          return Marker(
            point: LatLng(lat, lng),
            width: 44,
            height: 44,
            child: GestureDetector(
              onTap: () => _showDestinationDetail(doc.id),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.4),
                    blurRadius: 6,
                  )],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ),
          );
        }).toList();

        return MarkerLayer(markers: markers);
      },
    );
  }

  Widget _buildCurrentLocationLayer() {
    if (_currentLocation == null) return const SizedBox.shrink();
    return MarkerLayer(
      markers: [
        Marker(
          point: _currentLocation!,
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.5),
                    blurRadius: 8,
                  )],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportMarkers() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('reports').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status   = data['status'] ?? 'Menunggu';
          final category = data['category'] ?? '';
          if (status == 'Dihapus') return false;
          if (status == 'Selesai' && !_showCompleted) return false;
          if (_activeCategory != null && category != _activeCategory) return false;
          return true;
        }).toList();

        final markers = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final lat      = (data['latitude']  as num?)?.toDouble() ?? 0;
          final lng      = (data['longitude'] as num?)?.toDouble() ?? 0;
          final status   = data['status'] ?? 'Menunggu';
          final category = data['category'] as String?;
          final catColor = _categoryColor(category);
          final catIcon  = _categoryIcon(category);
          final Color markerColor = status == 'Selesai'
              ? const Color(0xFF10B981)
              : status == 'Diproses'
                  ? Colors.amber
                  : catColor;

          final markerChild = GestureDetector(
            onTap: () => _showReportDetail(doc.id),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: markerColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(color: markerColor.withOpacity(0.4), blurRadius: 6)],
              ),
              child: Icon(
                status == 'Selesai' ? LucideIcons.checkCircle : catIcon,
                color: Colors.white,
                size: 20,
              ),
            ),
          );

          return Marker(
            point: LatLng(lat, lng),
            width: 44,
            height: 44,
            child: markerChild,
          );
        }).toList();

        return MarkerLayer(markers: markers);
      },
    );
  }

  void _showDestinationDetail(String destinationId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DestinationDetailScreenFirestore(destinationId: destinationId),
      ),
    );
  }

  void _showReportDetail(String reportId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailScreenFirestore(reportId: reportId),
      ),
    );
  }

}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.active,
    required this.isDark,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color : (isDark ? const Color(0xFF1F2937) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? color : Colors.transparent, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: active ? Colors.white : color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : (isDark ? Colors.white : const Color(0xFF374151)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LayerChip extends StatelessWidget {
  const _LayerChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.active,
    required this.isDark,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? color : (isDark ? const Color(0xFF1F2937) : Colors.white),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active ? color : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
            width: 1.5,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 6)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active
                    ? Colors.white
                    : (isDark ? Colors.white : const Color(0xFF374151)),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              active ? LucideIcons.eye : LucideIcons.eyeOff,
              size: 12,
              color: active ? Colors.white.withOpacity(0.8) : color.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Search results panel ─────────────────────────────────────────────────────

class _SearchResultsPanel extends StatelessWidget {
  const _SearchResultsPanel({
    required this.query,
    required this.firestore,
    required this.isDark,
    required this.onTap,
  });

  final String query;
  final FirebaseFirestore firestore;
  final bool isDark;
  final void Function(String id, String type) onTap;

  static const _reportMeta = [
    ('Lingkungan & Bencana',     LucideIcons.leaf,        Color(0xFF10B981)),
    ('Transportasi & Mobilitas', LucideIcons.car,         Color(0xFF3B82F6)),
    ('Layanan Publik',           LucideIcons.building2,   Color(0xFF8B5CF6)),
    ('Ketertiban Sosial',        LucideIcons.shieldAlert, Color(0xFFF59E0B)),
  ];

  Color _reportColor(String? cat) {
    for (final c in _reportMeta) if (c.$1 == cat) return c.$3;
    return Colors.red;
  }

  IconData _reportIcon(String? cat) {
    for (final c in _reportMeta) if (c.$1 == cat) return c.$2;
    return LucideIcons.alertCircle;
  }

  bool _matchesQuery(String q, List<String> fields) =>
      fields.any((f) => f.toLowerCase().contains(q));

  Widget _emptyState() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.searchX, size: 18, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 8),
            Text('Tidak ditemukan',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                )),
          ],
        ),
      );

  Widget _resultList(List<_SearchItem> items) {
    final divColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(LucideIcons.listFilter, size: 14,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Text('${items.length} hasil ditemukan',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    )),
              ],
            ),
          ),
          Divider(height: 1, color: divColor),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: items.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: divColor),
              itemBuilder: (context, i) {
                final item = items[i];
                return ListTile(
                  dense: true,
                  onTap: () => onTap(item.id, item.type),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, size: 16, color: item.color),
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.subtitle.isNotEmpty)
                        Text(item.subtitle,
                            style: TextStyle(
                                fontSize: 11,
                                color: item.color,
                                fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      if (item.address.isNotEmpty)
                        Text(item.address,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF9CA3AF)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.badgeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(item.badge,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: item.badgeColor)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = query.toLowerCase();

    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('destinations').snapshots(),
      builder: (context, destSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: firestore.collection('reports').snapshots(),
          builder: (context, repSnap) {
            if (!destSnap.hasData || !repSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final items = <_SearchItem>[];

            // ── Destinations ────────────────────────────────────────
            for (final doc in destSnap.data!.docs) {
              final d = doc.data() as Map<String, dynamic>;
              if (d['isActive'] == false) continue;
              final name     = (d['name'] ?? '').toString();
              final category = (d['category'] ?? '').toString();
              final address  = (d['address'] ?? '').toString();
              final desc     = (d['description'] ?? '').toString();
              if (!_matchesQuery(q, [name, category, address, desc])) continue;
              items.add(_SearchItem(
                id:         doc.id,
                type:       'destination',
                title:      name,
                subtitle:   category,
                address:    address,
                icon:       LucideIcons.mapPin,
                color:      const Color(0xFF10B981),
                badge:      'Wisata',
                badgeColor: const Color(0xFF10B981),
              ));
            }

            // ── Reports ─────────────────────────────────────────────
            for (final doc in repSnap.data!.docs) {
              final d = doc.data() as Map<String, dynamic>;
              if ((d['status'] ?? '') == 'Selesai') continue;
              final title   = (d['title'] ?? '').toString();
              final cat     = (d['category'] ?? '').toString();
              final subCat  = (d['subCategory'] ?? '').toString();
              final address = (d['address'] ?? '').toString();
              if (!_matchesQuery(q, [title, cat, subCat, address])) continue;
              final status      = (d['status'] ?? 'Menunggu').toString();
              final statusColor = status == 'Diproses' ? Colors.amber : Colors.red;
              items.add(_SearchItem(
                id:         doc.id,
                type:       'report',
                title:      title,
                subtitle:   subCat.isNotEmpty ? subCat : cat,
                address:    address,
                icon:       _reportIcon(d['category'] as String?),
                color:      _reportColor(d['category'] as String?),
                badge:      status,
                badgeColor: statusColor,
              ));
            }

            if (items.isEmpty) return _emptyState();
            return _resultList(items);
          },
        );
      },
    );
  }
}

class _SearchItem {
  const _SearchItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.address,
    required this.icon,
    required this.color,
    required this.badge,
    required this.badgeColor,
  });
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String address;
  final IconData icon;
  final Color color;
  final String badge;
  final Color badgeColor;
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
      ],
    );
  }
}

