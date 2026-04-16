import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../components/level_up_modal.dart';
import '../services/poin_horas_service.dart';
import '../components/verification_guard.dart';
import 'check_in_screen.dart';
import 'destination_detail_screen_firestore.dart';

class JejakKesawanScreen extends StatefulWidget {
  final Function(double latitude, double longitude, String name)? onShowOnMap;
  
  const JejakKesawanScreen({
    super.key,
    this.onShowOnMap,
  });

  @override
  State<JejakKesawanScreen> createState() => _JejakKesawanScreenState();
}

class _JejakKesawanScreenState extends State<JejakKesawanScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TourismDestination> _allDestinations = [];
  List<TourismDestination> _medanDestinations = [];
  List<TourismDestination> _filteredDestinations = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Set<String> _visitedDestinations = {};
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTourismData();
    _loadVisitedDestinations();
    _fetchCurrentPosition();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _fetchCurrentPosition() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _currentPosition = pos);
    } catch (_) {}
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toInt()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  Future<String?> _addXP(int xp) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final userRef = _firestore.collection('users').doc(user.uid);
    String? levelUpTo;

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final data = snap.data() ?? {};

      final oldXP    = (data['currentXP'] as int?) ?? 0;
      final oldPoin  = (data['poinHoras']  as int?) ?? 0;
      final oldLevel = (data['level']      as String?) ?? 'Pemula';

      final newXP    = oldXP + xp;
      final newPoin  = oldPoin + PoinHorasService.poinCheckIn;
      final newLevel = UserProfile.levelFromXP(newXP);

      if (newLevel != oldLevel) levelUpTo = newLevel;

      tx.update(userRef, {
        'currentXP':     newXP,
        'poinHoras':     newPoin,
        'level':         newLevel,
        'totalCheckIns': FieldValue.increment(1),
        'lastCheckIn':   FieldValue.serverTimestamp(),
      });
    });

    return levelUpTo;
  }

  Future<void> _showXPModal(BuildContext ctx, String questName, int xp) async {
    await showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => _XPGainModal(questName: questName, xp: xp),
    );
  }

  Widget _imagePlaceholder(bool isDark, Color muted) => Container(
        height: 180,
        width: double.infinity,
        color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        child: Center(child: Icon(LucideIcons.image, size: 48, color: muted)),
      );

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterDestinations();
    });
  }

  void _filterDestinations() {
    if (_searchQuery.isEmpty) {
      _filteredDestinations = _allDestinations;
    } else {
      _filteredDestinations = _allDestinations.where((dest) {
        return dest.name.toLowerCase().contains(_searchQuery) ||
               dest.city.toLowerCase().contains(_searchQuery) ||
               dest.province.toLowerCase().contains(_searchQuery) ||
               dest.category.toLowerCase().contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _loadTourismData() async {
    try {
      final snap = await _firestore
          .collection('destinations')
          .where('isActive', isEqualTo: true)
          .get();
      final destinations = (snap.docs
          .map((doc) => TourismDestination.fromFirestore(doc.id, doc.data()))
          .toList())
        ..sort((a, b) => a.name.compareTo(b.name));
      setState(() {
        _allDestinations = destinations;
        _medanDestinations = destinations.where((d) {
          final cityMatch = d.city.toLowerCase().contains('medan');
          final latMatch = d.latitude >= 3.3 && d.latitude <= 3.9 &&
              d.longitude >= 98.4 && d.longitude <= 99.0;
          return cityMatch || latMatch;
        }).toList();
        _filteredDestinations = destinations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading destinations: $e');
    }
  }

  Future<void> _loadVisitedDestinations() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final checkInsSnapshot = await _firestore
          .collection('check_ins')
          .where('user_id', isEqualTo: user.uid)
          .where('status', isEqualTo: 'verified')
          .get();

      setState(() {
        _visitedDestinations = checkInsSnapshot.docs
            .map((doc) => doc.data()['destination_id'] as String)
            .toSet();
      });
    } catch (e) {
      debugPrint('Error loading visited destinations: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  // Generate quest nodes from Medan destinations
  List<KesawanQuestNode> get _questNodes {
    if (_medanDestinations.isEmpty) return [];
    
    return _medanDestinations.asMap().entries.map((entry) {
      final index = entry.key;
      final dest = entry.value;
      
      // Cek apakah destinasi sudah dikunjungi
      final isVisited = _visitedDestinations.contains(dest.id);
      
      // Tentukan state berdasarkan progress
      QuestState state;
      if (isVisited) {
        state = QuestState.completed;
      } else if (index == 0 || (index > 0 && _visitedDestinations.contains(_medanDestinations[index - 1].id))) {
        // Active jika ini destinasi pertama ATAU destinasi sebelumnya sudah completed
        state = QuestState.active;
      } else {
        state = QuestState.locked;
      }
      
      final double distanceMeters = _currentPosition != null
          ? Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              dest.latitude,
              dest.longitude,
            )
          : 0;

      return KesawanQuestNode(
        id: dest.id,
        name: dest.name,
        category: dest.category,
        distance: _currentPosition != null
            ? _formatDistance(distanceMeters)
            : '...',
        reward: PoinHorasService.xpCheckIn,
        state: state,
        imageUrl: dest.imageUrl,
        description: dest.description,
        latitude: dest.latitude,
        longitude: dest.longitude,
      );
    }).toList();
  }

  // Hitung progress
  int get _completedCount => _questNodes.where((n) => n.state == QuestState.completed).length;
  int get _totalCount => _questNodes.length;
  double get _progressValue => _completedCount / _totalCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFFFFFFF);
    final foregroundColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF10B981),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Jejak Kesawan'),
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF10B981),
          labelColor: const Color(0xFF10B981),
          unselectedLabelColor: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(
              icon: Icon(LucideIcons.mapPin, size: 20),
              text: 'Quest Timeline',
            ),
            Tab(
              icon: Icon(LucideIcons.building2, size: 20),
              text: 'Destinasi Populer',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuestTimeline(context),
          _buildPopularDestinations(context),
        ],
      ),
    );
  }

  Widget _buildQuestTimeline(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF10B981);
    final backgroundColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFFFFFFF);
    final foregroundColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final mutedColor = isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);
    final mutedForegroundColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final borderColor = isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB);

    if (_questNodes.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada data quest',
          style: TextStyle(color: mutedForegroundColor),
        ),
      );
    }

    return Column(
      children: [
        // HEADER PROGRESS CARD
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress Kesawan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: foregroundColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor, width: 1.5),
                    ),
                    child: Text(
                      '$_completedCount/$_totalCount',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 8,
                  child: LinearProgressIndicator(
                    value: _progressValue,
                    backgroundColor: mutedColor,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    LucideIcons.star,
                    size: 16,
                    color: mutedForegroundColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Total Reward: ${_completedCount * 50} XP',
                    style: TextStyle(
                      fontSize: 13,
                      color: mutedForegroundColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // VERTICAL QUEST TIMELINE
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
            itemCount: _questNodes.length,
            itemBuilder: (context, index) {
              final node = _questNodes[index];
              final isFirst = index == 0;
              final isLast = index == _questNodes.length - 1;
              
              return _buildQuestNode(
                context,
                node,
                isFirst,
                isLast,
                isDark,
                primaryColor,
                backgroundColor,
                foregroundColor,
                mutedColor,
                mutedForegroundColor,
                borderColor,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPopularDestinations(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFFFFFFF);
    final foregroundColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final mutedForegroundColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final borderColor = isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB);

    if (_allDestinations.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada data destinasi',
          style: TextStyle(color: mutedForegroundColor),
        ),
      );
    }

    return Column(
      children: [
        // Search Bar
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.search,
                size: 20,
                color: mutedForegroundColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari destinasi, kota, atau kategori...',
                    hintStyle: TextStyle(color: mutedForegroundColor),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(color: foregroundColor),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: Icon(
                    LucideIcons.x,
                    size: 18,
                    color: mutedForegroundColor,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
        
        // Results Count
        if (_searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Ditemukan ${_filteredDestinations.length} destinasi',
                  style: TextStyle(
                    fontSize: 13,
                    color: mutedForegroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        
        // Destinations List
        Expanded(
          child: _filteredDestinations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.searchX,
                        size: 48,
                        color: mutedForegroundColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tidak ada destinasi ditemukan',
                        style: TextStyle(
                          fontSize: 14,
                          color: mutedForegroundColor,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 80),
                  itemCount: _filteredDestinations.length,
                  itemBuilder: (context, index) {
                    final dest = _filteredDestinations[index];
                    return _buildDestinationCard(
                      context,
                      dest,
                      isDark,
                      backgroundColor,
                      foregroundColor,
                      mutedForegroundColor,
                      borderColor,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDestinationCard(
    BuildContext context,
    TourismDestination dest,
    bool isDark,
    Color backgroundColor,
    Color foregroundColor,
    Color mutedForegroundColor,
    Color borderColor,
  ) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DestinationDetailScreenFirestore(
              destinationId: dest.id,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: dest.imageUrl.isNotEmpty
                  ? Image.network(
                      dest.imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(isDark, mutedForegroundColor),
                    )
                  : _imagePlaceholder(isDark, mutedForegroundColor),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dest.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: foregroundColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 14,
                        color: mutedForegroundColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${dest.city}, ${dest.province}',
                          style: TextStyle(
                            fontSize: 13,
                            color: mutedForegroundColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981), width: 1),
                    ),
                    child: Text(
                      dest.category,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    dest.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: mutedForegroundColor,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.navigation,
                            size: 12,
                            color: mutedForegroundColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${dest.latitude.toStringAsFixed(2)}, ${dest.longitude.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: mutedForegroundColor,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 20,
                        color: mutedForegroundColor,
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
  }


  Widget _buildQuestNode(
    BuildContext context,
    KesawanQuestNode node,
    bool isFirst,
    bool isLast,
    bool isDark,
    Color primaryColor,
    Color backgroundColor,
    Color foregroundColor,
    Color mutedColor,
    Color mutedForegroundColor,
    Color borderColor,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // BAGIAN KIRI (JALUR TIMELINE / NODE)
          SizedBox(
            width: 70,
            child: Column(
              children: [
                // Garis Atas
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 3,
                      color: mutedColor,
                    ),
                  )
                else
                  const SizedBox(height: 20),

                // Node (Ikon Utama)
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: _getNodeColor(node.state, primaryColor, mutedColor),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: node.state == QuestState.active
                          ? primaryColor
                          : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: node.state == QuestState.active
                        ? [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    _getNodeIcon(node.state),
                    color: node.state == QuestState.locked
                        ? mutedForegroundColor
                        : Colors.white,
                    size: 24,
                  ),
                ),

                // Garis Bawah
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 3,
                      color: mutedColor,
                    ),
                  )
                else
                  const SizedBox(height: 20),
              ],
            ),
          ),

          // BAGIAN KANAN (KONTEN LANDMARK)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 24, top: 8),
              child: node.state == QuestState.locked
                  ? _buildLockedCard(
                      backgroundColor,
                      foregroundColor,
                      mutedForegroundColor,
                      borderColor,
                    )
                  : _buildUnlockedCard(
                      context,
                      node,
                      isDark,
                      primaryColor,
                      backgroundColor,
                      foregroundColor,
                      mutedForegroundColor,
                      borderColor,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedCard(
    Color backgroundColor,
    Color foregroundColor,
    Color mutedForegroundColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.lock,
              size: 18,
              color: mutedForegroundColor,
            ),
            const SizedBox(width: 8),
            Text(
              'LOCKED',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: mutedForegroundColor,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockedCard(
    BuildContext context,
    KesawanQuestNode node,
    bool isDark,
    Color primaryColor,
    Color backgroundColor,
    Color foregroundColor,
    Color mutedForegroundColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: node.state == QuestState.active ? primaryColor : borderColor,
          width: node.state == QuestState.active ? 2 : 1,
        ),
        boxShadow: node.state == QuestState.active
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row Atas: Judul & Badge XP
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  node.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: foregroundColor,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: node.state == QuestState.completed
                      ? primaryColor.withValues(alpha: 0.1)
                      : primaryColor,
                  borderRadius: BorderRadius.circular(8),
                  border: node.state == QuestState.completed
                      ? Border.all(color: primaryColor, width: 1.5)
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      node.state == QuestState.completed
                          ? LucideIcons.checkCircle2
                          : LucideIcons.star,
                      size: 12,
                      color: node.state == QuestState.completed
                          ? primaryColor
                          : Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${node.reward} XP',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: node.state == QuestState.completed
                            ? primaryColor
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Kategori & Jarak
          Row(
            children: [
              Icon(
                _getCategoryIcon(node.category),
                size: 14,
                color: mutedForegroundColor,
              ),
              const SizedBox(width: 6),
              Text(
                '${node.category} • ${node.distance}',
                style: TextStyle(
                  fontSize: 13,
                  color: mutedForegroundColor,
                ),
              ),
            ],
          ),

          // Tombol "Mulai Kunjungi" (hanya untuk State Active)
          if (node.state == QuestState.active) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final verified = await VerificationGuard.require(context);
                  if (!verified) return;

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckInScreen(
                        destinationId: node.id,
                        destinationName: node.name,
                        targetLocation: LatLng(node.latitude, node.longitude),
                        rewardXP: node.reward,
                      ),
                    ),
                  );
                  
                  if (result == true && mounted) {
                    final newLevel = await _addXP(node.reward);
                    await _loadVisitedDestinations();
                    if (mounted) {
                      await _showXPModal(context, node.name, node.reward);
                    }
                    if (newLevel != null && mounted) {
                      await LevelUpModal.show(context, newLevel);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.navigation, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Check-In Sekarang',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Info "Selesai" untuk completed state
          if (node.state == QuestState.completed) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  LucideIcons.checkCircle2,
                  size: 14,
                  color: primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Selesai dikunjungi',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getNodeColor(QuestState state, Color primaryColor, Color mutedColor) {
    switch (state) {
      case QuestState.completed:
        return primaryColor;
      case QuestState.active:
        return primaryColor;
      case QuestState.locked:
        return mutedColor;
    }
  }

  IconData _getNodeIcon(QuestState state) {
    switch (state) {
      case QuestState.completed:
        return LucideIcons.check;
      case QuestState.active:
        return LucideIcons.mapPin;
      case QuestState.locked:
        return LucideIcons.lock;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Sejarah':
        return LucideIcons.landmark;
      case 'Cafe/Kuliner':
        return LucideIcons.coffee;
      case 'Spot Foto':
        return LucideIcons.camera;
      default:
        return LucideIcons.mapPin;
    }
  }
}

enum QuestState {
  completed,
  active,
  locked,
}

class KesawanQuestNode {
  final String id;
  final String name;
  final String category;
  final String distance;
  final int reward;
  final QuestState state;
  final String? imageUrl;
  final String? description;
  final double latitude;
  final double longitude;

  const KesawanQuestNode({
    required this.id,
    required this.name,
    required this.category,
    required this.distance,
    required this.reward,
    required this.state,
    this.imageUrl,
    this.description,
    required this.latitude,
    required this.longitude,
  });
}

class TourismDestination {
  final String id;
  final String name;
  final String city;
  final String province;
  final String category;
  final String description;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final bool isActive;

  const TourismDestination({
    required this.id,
    required this.name,
    required this.city,
    required this.province,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    this.isActive = true,
  });

  factory TourismDestination.fromJson(Map<String, dynamic> json) {
    return TourismDestination(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      province: json['province'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      imageUrl: (json['image_url'] ?? json['imageUrl']) as String? ?? '',
    );
  }

  factory TourismDestination.fromFirestore(String docId, Map<String, dynamic> data) {
    return TourismDestination(
      id: docId,
      name: data['name'] as String? ?? '',
      city: data['city'] as String? ?? '',
      province: data['province'] as String? ?? 'Sumatera Utara',
      category: data['category'] as String? ?? '',
      description: data['description'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      imageUrl: data['imageUrl'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
    );
  }
}

// ── XP Gain Modal ─────────────────────────────────────────────────────────────

class _XPGainModal extends StatefulWidget {
  final String questName;
  final int xp;
  const _XPGainModal({required this.questName, required this.xp});

  @override
  State<_XPGainModal> createState() => _XPGainModalState();
}

class _XPGainModalState extends State<_XPGainModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.star,
                    size: 40,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  'XP Diperoleh!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 10),

                // XP Amount
                Text(
                  '+${widget.xp} XP',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF10B981),
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 10),

                // Quest name
                Text(
                  'Quest "${widget.questName}" selesai!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'XP telah ditambahkan ke profilmu',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 28),

                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Lanjutkan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
