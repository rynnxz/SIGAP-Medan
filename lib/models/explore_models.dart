import 'package:flutter/material.dart';

class FilterCategory {
  final String emoji;
  final String label;

  const FilterCategory({
    required this.emoji,
    required this.label,
  });
}

class Destination {
  final String title;
  final String category;
  final String distance;
  final String image;
  final Color categoryColor;

  const Destination({
    required this.title,
    required this.category,
    required this.distance,
    required this.image,
    required this.categoryColor,
  });
}
