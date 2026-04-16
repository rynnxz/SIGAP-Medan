import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class LandmarkDetailScreen extends StatefulWidget {
  final String title;
  final String imageUrl;
  final String description;
  final int rewardPoints;
  final double? latitude;
  final double? longitude;

  const LandmarkDetailScreen({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.rewardPoints,
    this.latitude,
    this.longitude,
  });

  @override
  State<LandmarkDetailScreen> createState() => _LandmarkDetailScreenState();
}

class _LandmarkDetailScreenState extends State<LandmarkDetailScreen> {
  bool _isCheckedIn = false;
  bool _isLoading = false;
  double? _distanceInKm;
  bool _isCalculatingDistance = false;

  @override
  void initState() {
    super.initState();
    _calculateDistance();
  }

  Future<void> _calculateDistance() async {
    setState(() {
      _isCalculatingDistance = true;
    });

    try {
      // Koordinat landmark (default Tjong A Fie jika tidak ada)
      final landmarkLat = widget.latitude ?? 3.5828;
      final landmarkLng = widget.longitude ?? 98.6793;

      // Dapatkan lokasi user saat ini
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Hitung jarak dalam meter
      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        landmarkLat,
        landmarkLng,
      );

      // Konversi ke kilometer
      setState(() {
        _distanceInKm = distanceInMeters / 1000;
        _isCalculatingDistance = false;
      });
    } catch (e) {
      setState(() {
        _distanceInKm = null;
        _isCalculatingDistance = false;
      });
    }
  }

  Future<void> _openGoogleMaps() async {
    final landmarkLat = widget.latitude ?? 3.5828;
    final landmarkLng = widget.longitude ?? 98.6793;
    
    final String googleMapsUrl = 
        "https://www.google.com/maps/dir/?api=1&destination=$landmarkLat,$landmarkLng";
    
    try {
      final Uri url = Uri.parse(googleMapsUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback: coba launch tanpa check
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat membuka Google Maps: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleCheckIn() async {
    setState(() {
      _isLoading = true;
    });

    // Simulasi cek GPS dan proses check-in
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _isCheckedIn = true;
      _isLoading = false;
    });

    // Tampilkan pesan sukses
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.checkCircle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Check-In Berhasil!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '+${widget.rewardPoints} Poin Horas telah ditambahkan',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
          padding: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Column(
        children: [
          // Header Gambar (Hero Section)
          _buildHeroImage(theme),
          
          // Konten Informasi
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul & Kategori
                  _buildTitleSection(theme),
                  
                  const SizedBox(height: 24),
                  
                  // Gamifikasi (Area Check-In)
                  _buildCheckInCard(theme),
                  
                  const SizedBox(height: 32),
                  
                  // Sejarah & Deskripsi
                  _buildDescriptionSection(theme),
                  
                  const SizedBox(height: 20),
                  
                  // Tombol Navigasi Google Maps
                  SizedBox(
                    width: double.infinity,
                    child: FButton(
                      onPress: _openGoogleMaps,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            LucideIcons.navigation,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Arahkan dengan Google Maps',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Fasilitas
                  _buildFacilitiesSection(theme),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage(ThemeData theme) {
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.network(
            widget.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: theme.primaryColor.withOpacity(0.1),
              child: const Center(
                child: Icon(
                  LucideIcons.image,
                  size: 64,
                  color: Colors.white24,
                ),
              ),
            ),
          ),
          
          // Gradient overlay untuk tombol back
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3],
              ),
            ),
          ),
          
          // Tombol Back (Kiri Atas)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          LucideIcons.arrowLeft,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Judul
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            height: 1.2,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        
        // Lokasi
        Row(
          children: [
            Icon(
              LucideIcons.mapPin,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Jl. Jend. Ahmad Yani, Kesawan',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
        
        // Jarak dari lokasi user
        if (_distanceInKm != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                LucideIcons.navigation,
                size: 16,
                color: const Color(0xFF10B981),
              ),
              const SizedBox(width: 6),
              Text(
                '${_distanceInKm!.toStringAsFixed(1)} km dari lokasi Anda',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ] else if (_isCalculatingDistance) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Menghitung jarak...',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCheckInCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF10B981).withOpacity(0.1),
            const Color(0xFF10B981).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.map,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Kunjungi & Dapatkan Poin!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Deskripsi
          Text(
            'Dapatkan +${widget.rewardPoints} Poin Horas dengan melakukan Check-In di lokasi ini.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tombol Check-In
          SizedBox(
            width: double.infinity,
            child: _isCheckedIn
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.checkCircle,
                          size: 18,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sudah Check-In',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : FButton(
                    onPress: _isLoading ? null : _handleCheckIn,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                LucideIcons.mapPin,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Check-In Lokasi Sekarang',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tentang Tempat Ini',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.description,
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildFacilitiesSection(ThemeData theme) {
    final facilities = [
      {'icon': LucideIcons.camera, 'label': 'Spot Foto'},
      {'icon': LucideIcons.coffee, 'label': 'Kafe'},
      {'icon': LucideIcons.ticket, 'label': 'Tiket Masuk'},
      {'icon': LucideIcons.wifi, 'label': 'WiFi Gratis'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fasilitas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: facilities.map((facility) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      facility['icon'] as IconData,
                      size: 24,
                      color: const Color(0xFF10B981),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      facility['label'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
