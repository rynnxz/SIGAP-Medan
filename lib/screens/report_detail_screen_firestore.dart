import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/report_interaction_service.dart';
import '../components/verification_guard.dart';

class ReportDetailScreenFirestore extends StatefulWidget {
  final String reportId;

  const ReportDetailScreenFirestore({
    super.key,
    required this.reportId,
  });

  @override
  State<ReportDetailScreenFirestore> createState() => _ReportDetailScreenFirestoreState();
}

class _ReportDetailScreenFirestoreState extends State<ReportDetailScreenFirestore> {
  final TextEditingController _commentController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _interactionService = ReportInteractionService();
  bool _isSubmitting = false;
  Map<String, dynamic>? _reportData;
  StreamSubscription<DocumentSnapshot>? _docSub;

  @override
  void initState() {
    super.initState();
    _docSub = _firestore
        .collection('reports')
        .doc(widget.reportId)
        .snapshots()
        .listen((snap) {
      if (mounted && snap.exists) {
        setState(() => _reportData = snap.data() as Map<String, dynamic>);
      }
    });
  }

  void _openFullscreenPhoto(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullscreenPhotoPage(imageUrl: url),
      ),
    );
  }

  @override
  void dispose() {
    _docSub?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _toggleUpvote() async {
    if (_isSubmitting) return;
    
    setState(() => _isSubmitting = true);

    final result = await _interactionService.toggleUpvote(widget.reportId);
    
    if (mounted) {
      setState(() => _isSubmitting = false);
      
      if (!result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to upvote'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addComment() async {
    if (_isSubmitting) return;

    final verified = await VerificationGuard.require(context);
    if (!verified) return;
    
    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    setState(() => _isSubmitting = true);

    final result = await _interactionService.addComment(
      reportId: widget.reportId,
      comment: comment,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (result['success']) {
        _commentController.clear();
        FocusScope.of(context).unfocus();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Komentar berhasil ditambahkan! +5 XP'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Gagal menambahkan komentar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return 'Baru saja';
    
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return 'Baru saja';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }

  String _formatFullDate(dynamic timestamp) {
    if (timestamp == null) return '-';
    
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return '-';
    }

    // Simple format without locale
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = _getMonthName(dateTime.month);
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$day $month $year, $hour:$minute';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return months[month - 1];
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Menunggu':
        return Colors.orange;
      case 'Diproses':
        return Colors.blue;
      case 'Selesai':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_reportData == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final reportData = _reportData!;
    final userId = _auth.currentUser?.uid;
    final upvotedBy = List<String>.from(reportData['upvotedBy'] ?? []);
    final isUpvoted = userId != null && upvotedBy.contains(userId);
    final upvotes = reportData['upvotes'] ?? 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      body: CustomScrollView(
            slivers: [
              // App Bar with Image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: isDark ? const Color(0xFF1F2937) : const Color(0xFF111827),
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: GestureDetector(
                    onTap: () {
                      final url = reportData['imageUrl'] ?? '';
                      if (url.isNotEmpty) _openFullscreenPhoto(url);
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          reportData['imageUrl'] ?? '',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFE5E7EB),
                              child: const Icon(LucideIcons.image, size: 64, color: Color(0xFF9CA3AF)),
                            );
                          },
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.maximize2, size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text('Perbesar', style: TextStyle(fontSize: 11, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Status
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1F2937) : Colors.white,
                        border: isDark ? Border.all(color: const Color(0xFF374151), width: 1) : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  reportData['title'] ?? 'Tanpa Judul',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(reportData['status'] ?? 'Menunggu').withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  reportData['status'] ?? 'Menunggu',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getStatusColor(reportData['status'] ?? 'Menunggu'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Category + subcategory
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  reportData['category'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ),
                              if ((reportData['subCategory'] as String?)?.isNotEmpty == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    reportData['subCategory'] as String,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Reporter
                          Row(
                            children: [
                              Icon(Icons.person_outline,
                                  size: 14,
                                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                              const SizedBox(width: 4),
                              Text(
                                'Dilaporkan oleh: ${reportData['reporterName'] ?? 'Anonim'}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Timeline Progress
                    _buildTimeline(reportData, isDark),

                    const SizedBox(height: 8),

                    // Description
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1F2937) : Colors.white,
                        border: isDark ? Border.all(color: const Color(0xFF374151), width: 1) : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Deskripsi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SelectableText(
                            reportData['description'] ?? '-',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Location Info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1F2937) : Colors.white,
                        border: isDark ? Border.all(color: const Color(0xFF374151), width: 1) : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lokasi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(LucideIcons.mapPin, size: 16, color: Color(0xFF10B981)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  reportData['address'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Lat / Long
                          Row(
                            children: [
                              Icon(LucideIcons.navigation, size: 14,
                                  color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  () {
                                    final lat = (reportData['latitude']  as num?)?.toStringAsFixed(6) ?? '-';
                                    final lng = (reportData['longitude'] as num?)?.toStringAsFixed(6) ?? '-';
                                    return '$lat, $lng';
                                  }(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Comments Section
                    _buildCommentsSection(isDark),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),

      // Bottom Action Bar
      bottomNavigationBar: Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 
                      MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Upvote Button
                GestureDetector(
                  onTap: _isSubmitting ? null : _toggleUpvote,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUpvoted
                          ? const Color(0xFF10B981).withOpacity(0.1)
                          : (isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isUpvoted ? const Color(0xFF10B981) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.thumbsUp,
                          size: 20,
                          color: isUpvoted ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$upvotes',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isUpvoted ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Comment Input
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1F2937)),
                    decoration: InputDecoration(
                      hintText: 'Tulis komentar...',
                      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Send Button
                GestureDetector(
                  onTap: _isSubmitting ? null : _addComment,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isSubmitting 
                            ? [Colors.grey, Colors.grey]
                            : [const Color(0xFF10B981), const Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(LucideIcons.send, size: 20, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildTimeline(Map<String, dynamic> reportData, bool isDark) {
    final status             = reportData['status'] ?? 'Menunggu';
    final reportedAt         = reportData['reportedAt'];
    final processedAt        = reportData['processedAt'];
    final completedAt        = reportData['completedAt'];
    final completionImageUrl = reportData['completionImageUrl'] as String?;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        border: isDark ? Border.all(color: const Color(0xFF374151), width: 1) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline Progres',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),

          // Dilaporkan
          _buildTimelineItem(
            icon: LucideIcons.fileText,
            title: 'Dilaporkan',
            time: _formatFullDate(reportedAt),
            isActive: true,
            isCompleted: true,
            isDark: isDark,
            showLine: true,
          ),

          // Diproses
          _buildTimelineItem(
            icon: LucideIcons.clock,
            title: 'Diproses',
            time: processedAt != null ? _formatFullDate(processedAt) : '-',
            isActive: status == 'Diproses' || status == 'Selesai',
            isCompleted: status == 'Selesai',
            isDark: isDark,
            showLine: true,
          ),

          // Selesai
          _buildTimelineItem(
            icon: LucideIcons.checkCircle,
            title: 'Selesai',
            time: completedAt != null ? _formatFullDate(completedAt) : '-',
            isActive: status == 'Selesai',
            isCompleted: status == 'Selesai',
            isDark: isDark,
            showLine: completionImageUrl != null && completionImageUrl.isNotEmpty,
          ),

          // Bukti Penyelesaian
          if (completionImageUrl != null && completionImageUrl.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF10B981), width: 2),
                      ),
                      child: const Icon(LucideIcons.camera,
                          size: 18, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bukti Penyelesaian',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  _FullscreenPhotoPage(imageUrl: completionImageUrl),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              completionImageUrl,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (_, child, progress) =>
                                  progress == null
                                      ? child
                                      : Container(
                                          height: 160,
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF374151)
                                                : const Color(0xFFF3F4F6),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Center(
                                              child: CircularProgressIndicator()),
                                        ),
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ketuk untuk memperbesar',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF6B7280)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String time,
    required bool isActive,
    required bool isCompleted,
    required bool isDark,
    required bool showLine,
  }) {
    final color = isActive ? const Color(0xFF10B981) : const Color(0xFF9CA3AF);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActive ? color.withOpacity(0.1) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            if (showLine)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? color : const Color(0xFF9CA3AF),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isActive 
                        ? (isDark ? Colors.white : const Color(0xFF1F2937))
                        : const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        border: isDark ? Border.all(color: const Color(0xFF374151), width: 1) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('reports')
                .doc(widget.reportId)
                .collection('comments')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Text('Komentar (0)');
              }

              final comments = snapshot.data!.docs;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Komentar (${comments.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (comments.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Belum ada komentar',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      separatorBuilder: (_, __) => const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final doc  = comments[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildCommentItem(doc.id, data, isDark);
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'Penjelajah':    return const Color(0xFF3B82F6);
      case 'Relawan':       return const Color(0xFF10B981);
      case 'Detektif Kota': return const Color(0xFF8B5CF6);
      case 'Penjaga Kota':  return const Color(0xFFF59E0B);
      default:              return const Color(0xFF6B7280);
    }
  }

  Widget _buildCommentItem(String commentId, Map<String, dynamic> data, bool isDark) {
    final currentUid = _auth.currentUser?.uid;
    final userName   = data['userName']  ?? 'Anonim';
    final userPhoto  = data['userPhoto'] as String?;
    final userLevel  = data['userLevel'] ?? 'Pemula';
    final commentText = data['comment']  ?? '';
    final isOwn      = data['userId'] == currentUid;
    final likedBy    = List<String>.from(data['likedBy'] ?? []);
    final isLiked    = currentUid != null && likedBy.contains(currentUid);
    final likes      = data['likes'] ?? 0;
    final editedAt   = data['editedAt'];
    final lvColor    = _levelColor(userLevel);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        CircleAvatar(
          radius: 18,
          backgroundImage: userPhoto != null && userPhoto.isNotEmpty
              ? NetworkImage(userPhoto)
              : null,
          backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
          child: (userPhoto == null || userPhoto.isEmpty)
              ? Text(
                  userName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + level badge + timestamp
              Row(
                children: [
                  Flexible(
                    child: Text(
                      userName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: lvColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: lvColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      userLevel,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: lvColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDateTime(data['timestamp']),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Comment text
              Text(
                commentText,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
                  height: 1.5,
                ),
              ),

              // Edited label
              if (editedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '(diedit)',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // Action row: like + edit/delete
              Row(
                children: [
                  // Like button
                  GestureDetector(
                    onTap: () async {
                      await _interactionService.toggleCommentLike(
                        reportId: widget.reportId,
                        commentId: commentId,
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLiked ? LucideIcons.heart : LucideIcons.heart,
                          size: 14,
                          color: isLiked
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$likes',
                          style: TextStyle(
                            fontSize: 12,
                            color: isLiked
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (isOwn) ...[
                    const SizedBox(width: 16),
                    // Edit button
                    GestureDetector(
                      onTap: () => _showEditCommentDialog(commentId, commentText, isDark),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.pencil,
                              size: 13,
                              color: isDark
                                  ? const Color(0xFF6B7280)
                                  : const Color(0xFF9CA3AF)),
                          const SizedBox(width: 3),
                          Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF6B7280)
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Delete button
                    GestureDetector(
                      onTap: () => _showDeleteCommentDialog(commentId),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.trash2,
                              size: 13, color: Color(0xFFEF4444)),
                          const SizedBox(width: 3),
                          const Text(
                            'Hapus',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (!isOwn && currentUid != null) ...[
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _showReportCommentDialog(commentId, isDark),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.flag,
                              size: 13,
                              color: isDark
                                  ? const Color(0xFF6B7280)
                                  : const Color(0xFF9CA3AF)),
                          const SizedBox(width: 3),
                          Text(
                            'Laporkan',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF6B7280)
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditCommentDialog(String commentId, String currentText, bool isDark) {
    final ctrl = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Komentar',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          maxLength: 500,
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1F2937)),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await _interactionService.editComment(
                reportId: widget.reportId,
                commentId: commentId,
                newText: ctrl.text,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['success'] == true
                        ? 'Komentar diperbarui'
                        : result['error'] ?? 'Gagal'),
                    backgroundColor: result['success'] == true
                        ? const Color(0xFF10B981)
                        : Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _showReportCommentDialog(String commentId, bool isDark) async {
    final reasons = [
      'Spam atau iklan',
      'Kata kasar / tidak sopan',
      'Informasi palsu / menyesatkan',
      'Konten tidak relevan',
    ];
    String? selectedReason;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final bgColor   = isDark ? const Color(0xFF1F2937) : Colors.white;
          final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
          final mutedColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
          return AlertDialog(
            backgroundColor: bgColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(LucideIcons.flag, size: 20, color: Color(0xFFEF4444)),
                const SizedBox(width: 8),
                Text(
                  'Laporkan Komentar',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih alasan pelaporan:',
                  style: TextStyle(color: mutedColor, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ...reasons.map((reason) => RadioListTile<String>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(reason, style: TextStyle(color: textColor, fontSize: 13)),
                  value: reason,
                  groupValue: selectedReason,
                  activeColor: const Color(0xFFEF4444),
                  onChanged: (v) => setDialogState(() => selectedReason = v),
                )),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Batal', style: TextStyle(color: mutedColor)),
              ),
              TextButton(
                onPressed: selectedReason == null
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        final result = await _interactionService.reportComment(
                          reportId: widget.reportId,
                          commentId: commentId,
                          reason: selectedReason!,
                        );
                        if (!mounted) return;
                        if (result['success'] == true) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text('Komentar telah dilaporkan'),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ));
                        } else if (result['error'] == 'already_reported') {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text('Kamu sudah melaporkan komentar ini'),
                            backgroundColor: const Color(0xFFF59E0B),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ));
                        }
                      },
                child: const Text(
                  'Laporkan',
                  style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteCommentDialog(String commentId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Komentar?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        content: Text(
          'Komentar akan dihapus permanen.',
          style: TextStyle(
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await _interactionService.deleteComment(
                reportId: widget.reportId,
                commentId: commentId,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['success'] == true
                        ? 'Komentar dihapus'
                        : result['error'] ?? 'Gagal'),
                    backgroundColor: result['success'] == true
                        ? const Color(0xFF10B981)
                        : Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _FullscreenPhotoPage extends StatelessWidget {
  const _FullscreenPhotoPage({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image,
              color: Colors.white54,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}
