import 'package:flutter/foundation.dart';

/// Service untuk manage wishlist destinasi
/// Untuk production, simpan ke SharedPreferences atau database
class WishlistService extends ChangeNotifier {
  static final WishlistService _instance = WishlistService._internal();
  factory WishlistService() => _instance;
  WishlistService._internal();

  final Set<String> _wishlistedIds = {};

  bool isWishlisted(String destinationId) {
    return _wishlistedIds.contains(destinationId);
  }

  void toggleWishlist(String destinationId) {
    if (_wishlistedIds.contains(destinationId)) {
      _wishlistedIds.remove(destinationId);
    } else {
      _wishlistedIds.add(destinationId);
    }
    notifyListeners();
  }

  List<String> getWishlistedIds() {
    return _wishlistedIds.toList();
  }

  int get wishlistCount => _wishlistedIds.length;
}
