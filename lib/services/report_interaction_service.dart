import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'poin_horas_service.dart';

class ReportInteractionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Toggle upvote on a report
  Future<Map<String, dynamic>> toggleUpvote(String reportId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }

      final reportRef = _firestore.collection('reports').doc(reportId);
      
      return await _firestore.runTransaction((transaction) async {
        final reportDoc = await transaction.get(reportRef);
        
        if (!reportDoc.exists) {
          throw Exception('Report not found');
        }

        final reportData = reportDoc.data()!;
        final upvotedBy = List<String>.from(reportData['upvotedBy'] ?? []);
        final isUpvoted = upvotedBy.contains(userId);
        final reportOwnerId = reportData['userId'] as String?;

        if (isUpvoted) {
          // Remove upvote
          upvotedBy.remove(userId);
          
          // Decrease report owner's reputation
          if (reportOwnerId != null && reportOwnerId != userId) {
            final ownerRef = _firestore.collection('users').doc(reportOwnerId);
            final ownerDoc = await transaction.get(ownerRef);
            if (ownerDoc.exists) {
              final currentReputation = (ownerDoc.data()?['reputation'] ?? 0) as int;
              transaction.update(ownerRef, {
                'reputation': currentReputation - 1,
                'helpfulVotes': FieldValue.increment(-1),
              });
            }
          }
        } else {
          // Add upvote
          upvotedBy.add(userId);
          
          // Increase report owner's reputation
          if (reportOwnerId != null && reportOwnerId != userId) {
            final ownerRef = _firestore.collection('users').doc(reportOwnerId);
            final ownerDoc = await transaction.get(ownerRef);
            if (ownerDoc.exists) {
              final currentReputation = (ownerDoc.data()?['reputation'] ?? 0) as int;
              final newReputation = currentReputation + 1;
              
              transaction.update(ownerRef, {
                'reputation': newReputation,
                'helpfulVotes': FieldValue.increment(1),
              });
              
              // Award badge if milestone reached
              if (newReputation == 10) {
                transaction.update(ownerRef, {
                  'badges': FieldValue.arrayUnion(['helpful_reporter']),
                });
              }
            }
          }
        }

        // Update report
        transaction.update(reportRef, {
          'upvotedBy': upvotedBy,
          'upvotes': upvotedBy.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return {
          'success': true,
          'isUpvoted': !isUpvoted,
          'upvotes': upvotedBy.length,
        };
      });
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Add comment to a report
  Future<Map<String, dynamic>> addComment({
    required String reportId,
    required String comment,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }

      // Validate comment
      final trimmedComment = comment.trim();
      if (trimmedComment.isEmpty) {
        return {
          'success': false,
          'error': 'Comment cannot be empty',
        };
      }

      if (trimmedComment.length < 3) {
        return {
          'success': false,
          'error': 'Comment too short (minimum 3 characters)',
        };
      }

      if (trimmedComment.length > 500) {
        return {
          'success': false,
          'error': 'Comment too long (maximum 500 characters)',
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
      final userName  = userData['name']     ?? 'Anonymous';
      final userPhoto = userData['photoUrl'];
      final userLevel = userData['level']    ?? 'Pemula';

      // Add comment
      final commentRef = await _firestore
          .collection('reports')
          .doc(reportId)
          .collection('comments')
          .add({
        'userId':    userId,
        'userName':  userName,
        'userPhoto': userPhoto,
        'userLevel': userLevel,
        'comment':   trimmedComment,
        'timestamp': FieldValue.serverTimestamp(),
        'likes':   0,
        'likedBy': [],
      });

      // Update user stats (gamification)
      await _firestore.collection('users').doc(userId).update({
        'totalComments': FieldValue.increment(1),
        'currentXP': FieldValue.increment(PoinHorasService.xpComment),
      });

      // Check for engagement badge
      final updatedUserDoc = await _firestore.collection('users').doc(userId).get();
      final totalComments = (updatedUserDoc.data()?['totalComments'] ?? 0) as int;
      
      if (totalComments == 10) {
        await _firestore.collection('users').doc(userId).update({
          'badges': FieldValue.arrayUnion(['active_commenter']),
        });
      }

      return {
        'success': true,
        'commentId': commentRef.id,
        'message': 'Comment added successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Delete comment (only owner or admin)
  Future<Map<String, dynamic>> deleteComment({
    required String reportId,
    required String commentId,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }

      // Get comment
      final commentDoc = await _firestore
          .collection('reports')
          .doc(reportId)
          .collection('comments')
          .doc(commentId)
          .get();

      if (!commentDoc.exists) {
        return {
          'success': false,
          'error': 'Comment not found',
        };
      }

      final commentData = commentDoc.data()!;
      final commentOwnerId = commentData['userId'] as String;

      // Check if user is owner or admin
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final isAdmin = (userDoc.data()?['accountType'] ?? 'user') == 'admin';

      if (commentOwnerId != userId && !isAdmin) {
        return {
          'success': false,
          'error': 'Not authorized to delete this comment',
        };
      }

      // Delete comment
      await _firestore
          .collection('reports')
          .doc(reportId)
          .collection('comments')
          .doc(commentId)
          .delete();

      // Update user stats
      await _firestore.collection('users').doc(commentOwnerId).update({
        'totalComments': FieldValue.increment(-1),
        'xp': FieldValue.increment(-5),
      });

      return {
        'success': true,
        'message': 'Comment deleted successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Edit own comment
  Future<Map<String, dynamic>> editComment({
    required String reportId,
    required String commentId,
    required String newText,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return {'success': false, 'error': 'Not authenticated'};

      final trimmed = newText.trim();
      if (trimmed.isEmpty || trimmed.length < 3) {
        return {'success': false, 'error': 'Komentar terlalu pendek'};
      }
      if (trimmed.length > 500) {
        return {'success': false, 'error': 'Komentar terlalu panjang'};
      }

      final commentRef = _firestore
          .collection('reports')
          .doc(reportId)
          .collection('comments')
          .doc(commentId);

      final commentDoc = await commentRef.get();
      if (!commentDoc.exists) return {'success': false, 'error': 'Komentar tidak ditemukan'};
      if ((commentDoc.data()?['userId'] as String?) != userId) {
        return {'success': false, 'error': 'Bukan komentar kamu'};
      }

      await commentRef.update({
        'comment':  trimmed,
        'editedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Like a comment
  Future<Map<String, dynamic>> toggleCommentLike({
    required String reportId,
    required String commentId,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
        };
      }

      final commentRef = _firestore
          .collection('reports')
          .doc(reportId)
          .collection('comments')
          .doc(commentId);

      return await _firestore.runTransaction((transaction) async {
        final commentDoc = await transaction.get(commentRef);
        
        if (!commentDoc.exists) {
          throw Exception('Comment not found');
        }

        final commentData = commentDoc.data()!;
        final likedBy = List<String>.from(commentData['likedBy'] ?? []);
        final isLiked = likedBy.contains(userId);

        if (isLiked) {
          likedBy.remove(userId);
        } else {
          likedBy.add(userId);
        }

        transaction.update(commentRef, {
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

  // Get report statistics
  Future<Map<String, dynamic>> getReportStats(String reportId) async {
    try {
      final reportDoc = await _firestore.collection('reports').doc(reportId).get();
      
      if (!reportDoc.exists) {
        return {
          'success': false,
          'error': 'Report not found',
        };
      }

      final reportData = reportDoc.data()!;
      
      // Get comments count
      final commentsSnapshot = await _firestore
          .collection('reports')
          .doc(reportId)
          .collection('comments')
          .get();

      return {
        'success': true,
        'upvotes': reportData['upvotes'] ?? 0,
        'comments': commentsSnapshot.docs.length,
        'status': reportData['status'] ?? 'Menunggu',
        'reportedAt': reportData['reportedAt'],
        'processedAt': reportData['processedAt'],
        'completedAt': reportData['completedAt'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Check if user has upvoted
  Future<bool> hasUserUpvoted(String reportId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final reportDoc = await _firestore.collection('reports').doc(reportId).get();
      if (!reportDoc.exists) return false;

      final upvotedBy = List<String>.from(reportDoc.data()?['upvotedBy'] ?? []);
      return upvotedBy.contains(userId);
    } catch (e) {
      return false;
    }
  }

  // Get user's comments on a report
  Stream<QuerySnapshot> getUserComments(String reportId, String userId) {
    return _firestore
        .collection('reports')
        .doc(reportId)
        .collection('comments')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get all comments for a report
  Stream<QuerySnapshot> getReportComments(String reportId) {
    return _firestore
        .collection('reports')
        .doc(reportId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Report a comment as inappropriate
  Future<Map<String, dynamic>> reportComment({
    required String reportId,
    required String commentId,
    required String reason,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      // Prevent duplicate reports from the same user
      final existing = await _firestore
          .collection('comment_reports')
          .where('commentId', isEqualTo: commentId)
          .where('reportedBy', isEqualTo: userId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return {'success': false, 'error': 'already_reported'};
      }

      final commentDoc = await _firestore
          .collection('reports')
          .doc(reportId)
          .collection('comments')
          .doc(commentId)
          .get();

      if (!commentDoc.exists) {
        return {'success': false, 'error': 'Comment not found'};
      }

      final commentData = commentDoc.data()!;

      await _firestore.collection('comment_reports').add({
        'commentId':        commentId,
        'reportId':         reportId,
        'commentText':      commentData['comment'] ?? '',
        'commentOwnerId':   commentData['userId'] ?? '',
        'commentOwnerName': commentData['userName'] ?? 'Anonim',
        'reportedBy':       userId,
        'reason':           reason,
        'status':           'pending',
        'createdAt':        FieldValue.serverTimestamp(),
      });

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
