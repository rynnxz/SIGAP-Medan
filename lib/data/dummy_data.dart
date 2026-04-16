import 'package:flutter/material.dart';
import '../models/explore_models.dart';

class DummyData {
  static final List<FilterCategory> categories = [
    const FilterCategory(emoji: '🏛️', label: 'Semua'),
    const FilterCategory(emoji: '🏛️', label: 'Sejarah'),
    const FilterCategory(emoji: '🍜', label: 'Kuliner Legendaris'),
    const FilterCategory(emoji: '☕', label: 'Tempat Nongkrong'),
  ];

  static final List<Destination> destinations = [
    const Destination(
      title: 'Gedung London Sumatra',
      category: 'Sejarah',
      distance: '200m dari Anda',
      image: 'https://images.unsplash.com/photo-1555881400-74d7acaacd8b?w=800',
      categoryColor: Color(0xFF1E3A8A), // Navy Blue
    ),
    const Destination(
      title: 'Tjong A Fie Mansion',
      category: 'Sejarah',
      distance: '450m dari Anda',
      image: 'https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=800',
      categoryColor: Color(0xFF1E3A8A),
    ),
    const Destination(
      title: 'Kopi Apek',
      category: 'Kuliner',
      distance: '320m dari Anda',
      image: 'https://images.unsplash.com/photo-1511920170033-f8396924c348?w=800',
      categoryColor: Color(0xFFF97316), // Orange
    ),
    const Destination(
      title: 'Sate Padang Al Fresco',
      category: 'Kuliner',
      distance: '580m dari Anda',
      image: 'https://images.unsplash.com/photo-1529042410759-befb1204b468?w=800',
      categoryColor: Color(0xFFF97316),
    ),
    const Destination(
      title: 'Istana Maimun',
      category: 'Sejarah',
      distance: '1.2km dari Anda',
      image: 'https://images.unsplash.com/photo-1609137144813-7d9921338f24?w=800',
      categoryColor: Color(0xFF1E3A8A),
    ),
    const Destination(
      title: 'Tip Top Restaurant',
      category: 'Kuliner',
      distance: '380m dari Anda',
      image: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800',
      categoryColor: Color(0xFFF97316),
    ),
  ];
}
