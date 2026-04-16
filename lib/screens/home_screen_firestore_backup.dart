import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../components/custom_bottom_nav.dart';
import 'jejak_kesawan_screen.dart';
import 'poin_horas_screen.dart';
import 'profile_screen.dart';
import 'report_detail_screen_firestore.dart';
import 'destination_detail_screen_firestore.dart';
import 'report_form_screen.dart';

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

    return Scaffold(
      extendBody: true,
      body: screens[_selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: CustomBottomNav(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
          ),
        ),
      ),
    );
  }

  Widget _buildMapScreen() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _medanCenter,
            initialZoom: 13.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),
            _buildDestinationMarkers(),
            _buildReportMarkers(),
          ],
        ),
      ],
    );
  }

  Widget _buildDestinationMarkers() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('destinations').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final markers = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final lat = double.tryParse(data['latitude']?.toString() ?? '0') ?? 0;
          final lng = double.tryParse(data['longitude']?.toString() ?? '0') ?? 0;

          return Marker(
            point: LatLng(lat, lng),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => _showDestinationDetail(doc.id),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(LucideIcons.mapPin, color: Colors.white, size: 20),
              ),
            ),
          );
        }).toList();

        return MarkerLayer(markers: markers);
      },
    );
  }

  Widget _buildReportMarkers() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('reports').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final markers = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final lat = double.tryParse(data['latitude']?.toString() ?? '0') ?? 0;
          final lng = double.tryParse(data['longitude']?.toString() ?? '0') ?? 0;
          final status = data['status'] ?? 'Menunggu';

          return Marker(
            point: LatLng(lat, lng),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => _showReportDetail(doc.id),
              child: Container(
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(LucideIcons.alertCircle, color: Colors.white, size: 20),
              ),
            ),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Selesai':
        return Colors.green;
      case 'Diproses':
        return Colors.amber;
      default:
        return Colors.red;
    }
  }
}
