import 'package:flutter/material.dart';
import '../models/explore_models.dart';
import '../data/dummy_data.dart';
import '../components/jejak_kesawan_card.dart';
import 'landmark_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  int _selectedCategoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return CustomScrollView(
      slivers: [
        // Header dengan judul
        SliverAppBar(
          expandedHeight: 120.0,
          pinned: true,
          backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              'Explore Medan',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1F2937),
                fontWeight: FontWeight.bold,
              ),
            ),
            titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark 
                    ? [const Color(0xFF1E3A8A), const Color(0xFF1F2937)]
                    : [const Color(0xFF1E3A8A), Colors.white],
                ),
              ),
            ),
          ),
        ),
        
        // Card Jejak Kesawan Premium
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: const JejakKesawanCard(),
          ),
        ),
        
        // Filter Categories
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Destinasi Populer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 45,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: DummyData.categories.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final category = DummyData.categories[index];
                      final isActive = _selectedCategoryIndex == index;
                      return FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(category.emoji, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              category.label,
                              style: TextStyle(
                                color: isActive ? Colors.white : (isDark ? const Color(0xFF9CA3AF) : Colors.grey[700]),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        selected: isActive,
                        onSelected: (value) {
                          setState(() {
                            _selectedCategoryIndex = index;
                          });
                        },
                        backgroundColor: isDark ? const Color(0xFF374151) : Colors.grey[200],
                        selectedColor: const Color(0xFF10B981),
                        checkmarkColor: Colors.white,
                        elevation: isActive ? 3 : 1,
                        shadowColor: Colors.black.withValues(alpha: 0.2),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                          side: BorderSide(
                            color: isActive 
                              ? const Color(0xFF10B981) 
                              : (isDark ? const Color(0xFF4B5563) : Colors.grey[300]!),
                            width: 1.5,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Grid Destinasi
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final destination = DummyData.destinations[index];
                return _buildDestinationCard(destination);
              },
              childCount: DummyData.destinations.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildDestinationCard(Destination destination) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: () {
        // Navigasi ke LandmarkDetailScreen dengan data destinasi
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LandmarkDetailScreen(
              title: destination.title,
              imageUrl: destination.image,
              description: _getDestinationDescription(destination.title),
              rewardPoints: _getRewardPoints(destination.category),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: const Color(0xFF374151), width: 1) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
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
              child: Image.network(
                destination.image,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    color: isDark ? const Color(0xFF374151) : Colors.grey[300],
                    child: Icon(
                      Icons.image, 
                      size: 40,
                      color: isDark ? const Color(0xFF6B7280) : Colors.grey[600],
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text('📍', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            destination.distance,
                            style: TextStyle(
                              fontSize: 11, 
                              color: isDark ? const Color(0xFF9CA3AF) : Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: destination.categoryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        destination.category,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: destination.categoryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDestinationDescription(String title) {
    final descriptions = {
      'Gedung London Sumatra': 'Gedung bersejarah yang dulunya merupakan kantor pusat London Sumatra Plantation. Arsitektur kolonial Belanda yang megah dengan detail ornamen klasik menjadi daya tarik utama. Gedung ini menjadi simbol kejayaan industri perkebunan di Sumatera Utara pada masa kolonial. Bangunan ini memiliki nilai historis tinggi dan sering menjadi lokasi foto favorit wisatawan.',
      
      'Tjong A Fie Mansion': 'Rumah megah peninggalan saudagar tembakau Tjong A Fie yang dibangun pada awal abad ke-20. Bangunan bergaya arsitektur Tionghoa-Eropa ini menjadi saksi bisu kejayaan perdagangan tembakau di Medan. Di dalamnya terdapat berbagai koleksi antik, furnitur mewah, dan foto-foto bersejarah yang menceritakan kehidupan keluarga Tjong A Fie. Mansion ini telah direstorasi dengan baik dan dibuka untuk umum sebagai museum.',
      
      'Kopi Apek': 'Kedai kopi legendaris yang telah berdiri sejak tahun 1960-an. Tempat ini terkenal dengan kopi tubruk khas Medan yang diseduh dengan cara tradisional. Suasana vintage dan autentik membuat pengunjung seolah kembali ke masa lalu. Kopi Apek menjadi tempat favorit para pecinta kopi untuk menikmati secangkir kopi sambil berbincang santai. Menu andalannya adalah kopi tubruk dengan roti bakar.',
      
      'Sate Padang Al Fresco': 'Warung sate padang yang terkenal dengan cita rasa autentik dan bumbu kuah yang kental. Sudah berdiri sejak puluhan tahun, tempat ini selalu ramai dikunjungi pecinta kuliner. Sate dagingnya empuk dengan bumbu kuah khas Padang yang gurih dan sedikit pedas. Lokasi yang strategis di kawasan Kesawan membuatnya mudah dijangkau. Harga terjangkau dengan porsi yang mengenyangkan.',
      
      'Istana Maimun': 'Istana Maimun adalah istana Kesultanan Deli yang dibangun pada tahun 1888 oleh Sultan Ma\'moen Al Rasyid. Arsitektur istana memadukan gaya Melayu, Mughal, Spanyol, dan Italia yang sangat memukau. Istana ini masih dihuni oleh keturunan Sultan dan sebagian dibuka untuk umum sebagai objek wisata. Di dalamnya terdapat berbagai koleksi pusaka kerajaan, meriam kuno, dan singgasana sultan yang megah.',
      
      'Tip Top Restaurant': 'Restoran legendaris yang telah berdiri sejak tahun 1934. Tempat ini menjadi saksi perjalanan sejarah Kota Medan dan pernah menjadi tempat favorit para pejabat kolonial Belanda. Hingga kini, Tip Top masih mempertahankan cita rasa autentik dan suasana klasik yang kental dengan nuansa tempo dulu. Menu andalannya adalah es krim, kue-kue kering, dan berbagai hidangan Eropa klasik.',
    };
    
    return descriptions[title] ?? 
      'Destinasi menarik di kawasan Kesawan, Medan. Tempat ini memiliki nilai sejarah dan budaya yang tinggi, cocok untuk dikunjungi bersama keluarga atau teman. Nikmati pengalaman wisata heritage yang tak terlupakan di jantung kota Medan.';
  }

  int _getRewardPoints(String category) {
    // Sejarah: 20 poin, Kuliner: 15 poin, lainnya: 10 poin
    if (category.toLowerCase().contains('sejarah')) {
      return 20;
    } else if (category.toLowerCase().contains('kuliner')) {
      return 15;
    } else {
      return 10;
    }
  }
}
