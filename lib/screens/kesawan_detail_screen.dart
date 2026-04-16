import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'landmark_detail_screen.dart';

class KesawanDetailScreen extends StatelessWidget {
  const KesawanDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero SliverAppBar dengan gambar megah
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gambar Hero Kesawan
                  Image.network(
                    'https://images.unsplash.com/photo-1555881400-74d7acaacd8b?w=800',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: theme.primaryColor.withOpacity(0.1),
                      child: const Icon(LucideIcons.image, size: 64),
                    ),
                  ),
                  // Gradient overlay untuk keterbacaan teks
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Konten utama
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // A. Bagian Judul & Badge
                  _buildTitleSection(theme),
                  
                  const SizedBox(height: 24),
                  
                  // B. Integrasi Gamifikasi (Poin Horas)
                  _buildGamificationCard(theme),
                  
                  const SizedBox(height: 24),
                  
                  // C. Deskripsi Sejarah
                  _buildDescriptionSection(theme),
                  
                  const SizedBox(height: 32),
                  
                  // D. Carousel Landmark
                  _buildLandmarkCarousel(theme),
                  
                  const SizedBox(height: 32),
                  
                  // E. Peta Rute Mini
                  _buildRouteMap(theme),
                  
                  const SizedBox(height: 32),
                ],
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
        // Judul Utama
        Text(
          'Jejak Kesawan',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            height: 1.2,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        
        // Badge dan Lokasi
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.compass,
                    size: 14,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Pariwisata & Budaya',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              LucideIcons.mapPin,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 4),
            Text(
              'Medan Barat',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGamificationCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.footprints,
              color: Color(0xFF10B981),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kunjungi 3 landmark di rute ini',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Klaim ',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const Text(
                      '+50 Poin Horas',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    Text(
                      '!',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          FButton(
            onPress: () {},
            child: const Text('Mulai Tur'),
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
          'Tentang Kawasan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Kawasan Kesawan adalah saksi bisu kejayaan kota Medan di masa lampau. Menyusuri jalan ini ibarat memutar waktu kembali ke era kolonial dengan deretan arsitektur memukau yang masih berdiri kokoh hingga kini.\n\n'
          'Dari Tjong A Fie Mansion yang megah hingga gedung-gedung bersejarah lainnya, setiap sudut Kesawan menyimpan cerita tentang masa keemasan perdagangan dan kebudayaan Medan. Nikmati perjalanan heritage yang tak terlupakan di jantung kota.',
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildLandmarkCarousel(ThemeData theme) {
    final landmarks = [
      {
        'name': 'Tjong A Fie Mansion',
        'image': 'https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=400',
        'distance': '200m',
      },
      {
        'name': 'Gedung Lonsum',
        'image': 'https://images.unsplash.com/photo-1583037189850-1921ae7c6c22?w=400',
        'distance': '450m',
      },
      {
        'name': 'Tip Top Restaurant',
        'image': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400',
        'distance': '600m',
      },
      {
        'name': 'Mesjid Raya',
        'image': 'https://images.unsplash.com/photo-1564769625905-50e93615e769?w=400',
        'distance': '800m',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Landmark Utama',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: landmarks.length,
            itemBuilder: (context, index) {
              final landmark = landmarks[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < landmarks.length - 1 ? 16 : 0,
                ),
                child: _buildLandmarkCard(context, theme, landmark),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLandmarkCard(BuildContext context, ThemeData theme, Map<String, String> landmark) {
    return GestureDetector(
      onTap: () {
        // Navigasi ke LandmarkDetailScreen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LandmarkDetailScreen(
              title: landmark['name']!,
              imageUrl: landmark['image']!,
              description: _getLandmarkDescription(landmark['name']!),
              rewardPoints: 15,
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar landmark
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                landmark['image']!,
                height: 120,
                width: 160,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  color: theme.primaryColor.withOpacity(0.1),
                  child: const Icon(LucideIcons.image, size: 32),
                ),
              ),
            ),
            
            // Info landmark
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    landmark['name']!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.navigation,
                        size: 12,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        landmark['distance']!,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
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
  }

  String _getLandmarkDescription(String name) {
    final descriptions = {
      'Tjong A Fie Mansion': 'Rumah megah peninggalan saudagar tembakau Tjong A Fie yang dibangun pada awal abad ke-20. Bangunan bergaya arsitektur Tionghoa-Eropa ini menjadi saksi bisu kejayaan perdagangan tembakau di Medan. Di dalamnya terdapat berbagai koleksi antik, furnitur mewah, dan foto-foto bersejarah yang menceritakan kehidupan keluarga Tjong A Fie.',
      'Gedung Lonsum': 'Gedung bersejarah yang dulunya merupakan kantor pusat London Sumatra Plantation. Arsitektur kolonial Belanda yang megah dengan detail ornamen klasik menjadi daya tarik utama. Gedung ini menjadi simbol kejayaan industri perkebunan di Sumatera Utara pada masa kolonial.',
      'Tip Top Restaurant': 'Restoran legendaris yang telah berdiri sejak tahun 1934. Tempat ini menjadi saksi perjalanan sejarah Kota Medan dan pernah menjadi tempat favorit para pejabat kolonial Belanda. Hingga kini, Tip Top masih mempertahankan cita rasa autentik dan suasana klasik yang kental dengan nuansa tempo dulu.',
      'Mesjid Raya': 'Masjid Raya Al-Mashun adalah masjid bersejarah yang dibangun pada tahun 1906 oleh Sultan Ma\'moen Al Rasyid Perkasa Alamsyah. Arsitektur masjid ini memadukan gaya Timur Tengah, India, dan Spanyol yang sangat memukau. Masjid ini menjadi landmark penting dan pusat kegiatan keagamaan di Kota Medan.',
    };
    
    return descriptions[name] ?? 'Tempat bersejarah yang menarik untuk dikunjungi di kawasan Kesawan, Medan.';
  }

  Widget _buildRouteMap(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rute Berjalan Kaki',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Placeholder peta
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.05),
                  ),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1524661135-423995f22d0b?w=800',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.map,
                            size: 48,
                            color: theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Peta Rute',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Info overlay
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.footprints,
                              size: 16,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '2.5 km',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.clock,
                              size: 16,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '45 menit',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
