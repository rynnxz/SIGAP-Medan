import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DestinationInteractionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Toggle favorite on a destination
  Future<Map<String, dynamic>> toggleFavorite(String destinationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }

      final destRef = _firestore.collection('destinations').doc(destinationId);
      
      return await _firestore.runTransaction((transaction) async {
        final destDoc = await transaction.get(destRef);
        
        if (!destDoc.exists) {
          throw Exception('Destination not found');
        }

        final destData = destDoc.data()!;
        final favoritedBy = List<String>.from(destData['favoritedBy'] ?? []);
        final isFavorited = favoritedBy.contains(userId);

        if (isFavorited) {
          favoritedBy.remove(userId);
        } else {
          favoritedBy.add(userId);
        }

        transaction.update(destRef, {
          'favoritedBy': favoritedBy,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update user favorites list
        final userRef = _firestore.collection('users').doc(userId);
        if (isFavorited) {
          transaction.update(userRef, {
            'favoriteDestinations': FieldValue.arrayRemove([destinationId]),
          });
        } else {
          transaction.update(userRef, {
            'favoriteDestinations': FieldValue.arrayUnion([destinationId]),
          });
        }

        return {
          'success': true,
          'isFavorited': !isFavorited,
          'favoritesCount': favoritedBy.length,
        };
      });
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Add review to a destination
  Future<Map<String, dynamic>> addReview({
    required String destinationId,
    required String review,
    required int rating,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }

      // Validate review
      final trimmedReview = review.trim();
      if (trimmedReview.isEmpty) {
        return {
          'success': false,
          'error': 'Review cannot be empty',
        };
      }

      if (trimmedReview.length < 10) {
        return {
          'success': false,
          'error': 'Review too short (minimum 10 characters)',
        };
      }

      if (trimmedReview.length > 500) {
        return {
          'success': false,
          'error': 'Review too long (maximum 500 characters)',
        };
      }

      // Validate rating
      if (rating < 1 || rating > 5) {
        return {
          'success': false,
          'error': 'Rating must be between 1 and 5',
        };
      }

      // Check if user already reviewed
      final existingReview = await _firestore
          .collection('destinations')
          .doc(destinationId)
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .get();

      if (existingReview.docs.isNotEmpty) {
        return {
          'success': false,
          'error': 'You have already reviewed this destination',
        };
      }

      // Get user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return {
          'success': false,
          'error': 'User profile not found',
        };
      }

      final userData = userDoc.data()!;
      final userName = userData['name'] ?? 'Anonymous';
      final userPhoto = userData['photoUrl'];

      // Add review
      final reviewRef = await _firestore
          .collection('destinations')
          .doc(destinationId)
          .collection('reviews')
          .add({
        'userId': userId,
        'userName': userName,
        'userPhoto': userPhoto,
        'review': trimmedReview,
        'rating': rating,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': [],
      });

      // Update destination rating
      await _updateDestinationRating(destinationId);

      // Update user stats (gamification)
      await _firestore.collection('users').doc(userId).update({
        'totalReviews': FieldValue.increment(1),
        'xp': FieldValue.increment(10), // 10 XP for reviewing
      });

      // Check for reviewer badge
      final updatedUserDoc = await _firestore.collection('users').doc(userId).get();
      final totalReviews = (updatedUserDoc.data()?['totalReviews'] ?? 0) as int;
      
      if (totalReviews == 5) {
        await _firestore.collection('users').doc(userId).update({
          'badges': FieldValue.arrayUnion(['active_reviewer']),
        });
      }

      return {
        'success': true,
        'reviewId': reviewRef.id,
        'message': 'Review added successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Update destination average rating
  Future<void> _updateDestinationRating(String destinationId) async {
    final reviewsSnapshot = await _firestore
        .collection('destinations')
        .doc(destinationId)
        .collection('reviews')
        .get();

    if (reviewsSnapshot.docs.isEmpty) {
      await _firestore.collection('destinations').doc(destinationId).update({
        'rating': 0.0,
        'reviews': 0,
      });
      return;
    }

    double totalRating = 0;
    for (var doc in reviewsSnapshot.docs) {
      totalRating += (doc.data()['rating'] ?? 0) as int;
    }

    final averageRating = totalRating / reviewsSnapshot.docs.length;

    await _firestore.collection('destinations').doc(destinationId).update({
      'rating': double.parse(averageRating.toStringAsFixed(1)),
      'reviews': reviewsSnapshot.docs.length,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete review (only owner or admin)
  Future<Map<String, dynamic>> deleteReview({
    required String destinationId,
    required String reviewId,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }

      // Get review
      final reviewDoc = await _firestore
          .collection('destinations')
          .doc(destinationId)
          .collection('reviews')
          .doc(reviewId)
          .get();

      if (!reviewDoc.exists) {
        return {
          'success': false,
          'error': 'Review not found',
        };
      }

      final reviewData = reviewDoc.data()!;
      final reviewOwnerId = reviewData['userId'] as String;

      // Check if user is owner or admin
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final isAdmin = (userDoc.data()?['accountType'] ?? 'user') == 'admin';

      if (reviewOwnerId != userId && !isAdmin) {
        return {
          'success': false,
          'error': 'Not authorized to delete this review',
        };
      }

      // Delete review
      await _firestore
          .collection('destinations')
          .doc(destinationId)
          .collection('reviews')
          .doc(reviewId)
          .delete();

      // Update destination rating
      await _updateDestinationRating(destinationId);

      // Update user stats
      await _firestore.collection('users').doc(reviewOwnerId).update({
        'totalReviews': FieldValue.increment(-1),
        'xp': FieldValue.increment(-10),
      });

      return {
        'success': true,
        'message': 'Review deleted successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Like a review
  Future<Map<String, dynamic>> toggleReviewLike({
    required String destinationId,
    required String reviewId,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }

      final reviewRef = _firestore
          .collection('destinations')
          .doc(destinationId)
          .collection('reviews')
          .doc(reviewId);

      return await _firestore.runTransaction((transaction) async {
        final reviewDoc = await transaction.get(reviewRef);
        
        if (!reviewDoc.exists) {
          throw Exception('Review not found');
        }

        final reviewData = reviewDoc.data()!;
        final likedBy = List<String>.from(reviewData['likedBy'] ?? []);
        final isLiked = likedBy.contains(userId);

        if (isLiked) {
          likedBy.remove(userId);
        } else {
          likedBy.add(userId);
        }

        transaction.update(reviewRef, {
          'likedBy': likedBy,
          'likes': likedBy.length,
        });

        return {
          'success': true,
          'isLiked': !isLiked,
          'likes': likedBy.length,
        };
      });
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get destination statistics
  Future<Map<String, dynamic>> getDestinationStats(String destinationId) async {
    try {
      final destDoc = await _firestore.collection('destinations').doc(destinationId).get();
      
      if (!destDoc.exists) {
        return {
          'success': false,
          'error': 'Destination not found',
        };
      }

      final destData = destDoc.data()!;
      
      // Get reviews count
      final reviewsSnapshot = await _firestore
          .collection('destinations')
          .doc(destinationId)
          .collection('reviews')
          .get();

      return {
        'success': true,
        'rating': destData['rating'] ?? 0.0,
        'reviews': reviewsSnapshot.docs.length,
        'favorites': (destData['favoritedBy'] as List?)?.length ?? 0,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Check if user has favorited
  Future<bool> hasUserFavorited(String destinationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final destDoc = await _firestore.collection('destinations').doc(destinationId).get();
      if (!destDoc.exists) return false;

      final favoritedBy = List<String>.from(destDoc.data()?['favoritedBy'] ?? []);
      return favoritedBy.contains(userId);
    } catch (e) {
      return false;
    }
  }

  // Check if user has reviewed
  Future<bool> hasUserReviewed(String destinationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final reviewSnapshot = await _firestore
          .collection('destinations')
          .doc(destinationId)
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .get();

      return reviewSnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get user's review on a destination
  Future<DocumentSnapshot?> getUserReview(String destinationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final reviewSnapshot = await _firestore
          .collection('destinations')
          .doc(destinationId)
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .get();

      if (reviewSnapshot.docs.isEmpty) return null;
      return reviewSnapshot.docs.first;
    } catch (e) {
      return null;
    }
  }

  // Get all reviews for a destination
  Stream<QuerySnapshot> getDestinationReviews(String destinationId) {
    return _firestore
        .collection('destinations')
        .doc(destinationId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
