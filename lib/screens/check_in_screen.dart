import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/location_verification_service.dart';

class CheckInScreen extends StatefulWidget {
  final String destinationId;
  final String destinationName;
  final LatLng targetLocation;
  final int rewardXP;

  const CheckInScreen({
    super.key,
    required this.destinationId,
    required this.destinationName,
    required this.targetLocation,
    required this.rewardXP,
  });

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> with SingleTickerProviderStateMixin {
  bool _isVerifying = false;
  LocationCheckResult? _result;
  late AnimationController _pulseController;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startCheckIn() async {
    setState(() {
      _isVerifying = true;
      _result = null;
    });

    // Simulasi proses verifikasi dengan delay
    await Future.delayed(const Duration(milliseconds: 500));

    final result = await LocationVerificationService.verifyLocation(
      widget.targetLocation,
    );

    setState(() {
      _isVerifying = false;
      _result = result;
    });

    // Jika berhasil, simpan ke Firestore lalu auto close
    if (result.success) {
      try {
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('check_ins').add({
            'user_id': user.uid,
            'destination_id': widget.destinationId,
            'destination_name': widget.destinationName,
            'status': 'verified',
            'reward_xp': widget.rewardXP,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        debugPrint('Error saving check-in: $e');
      }
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB);
    final cardColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final foregroundColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final mutedColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Check-In Lokasi'),
        backgroundColor: cardColor,
        foregroundColor: foregroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              
              // Destination Info Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Animated GPS Icon
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_pulseController.value * 0.1),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.mapPin,
                              size: 40,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      widget.destinationName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: foregroundColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF10B981),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.star,
                            size: 16,
                            color: Color(0xFF10B981),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '+${widget.rewardXP} XP Reward',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      'Pastikan Anda berada dalam radius 50m dari lokasi destinasi',
                      style: TextStyle(
                        fontSize: 13,
                        color: mutedColor,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Result Display
              if (_result != null) ...[
                _buildResultCard(_result!, isDark, cardColor, foregroundColor, mutedColor),
                const SizedBox(height: 24),
              ],
              
              // Check-In Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _startCheckIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark 
                        ? const Color(0xFF374151) 
                        : const Color(0xFFE5E7EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isVerifying
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Memverifikasi Lokasi...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.navigation, size: 20),
                            SizedBox(width: 12),
                            Text(
                              'Mulai Check-In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Info Text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.shield,
                    size: 14,
                    color: mutedColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Sistem anti-fake GPS aktif',
                    style: TextStyle(
                      fontSize: 12,
                      color: mutedColor,
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(
    LocationCheckResult result,
    bool isDark,
    Color cardColor,
    Color foregroundColor,
    Color mutedColor,
  ) {
    final isSuccess = result.success;
    final isSuspicious = result.suspiciousActivity;
    
    Color statusColor;
    IconData statusIcon;
    
    if (isSuspicious) {
      statusColor = const Color(0xFFEF4444); // Red
      statusIcon = LucideIcons.shieldAlert;
    } else if (isSuccess) {
      statusColor = const Color(0xFF10B981); // Green
      statusIcon = LucideIcons.checkCircle2;
    } else {
      statusColor = const Color(0xFFF59E0B); // Amber
      statusIcon = LucideIcons.alertCircle;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            statusIcon,
            size: 48,
            color: statusColor,
          ),
          const SizedBox(height: 12),
          Text(
            result.message,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: foregroundColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (result.distance != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.ruler,
                  size: 14,
                  color: mutedColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Jarak: ${result.distance!.toStringAsFixed(1)}m',
                  style: TextStyle(
                    fontSize: 12,
                    color: mutedColor,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  LucideIcons.target,
                  size: 14,
                  color: mutedColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Akurasi: ${result.accuracy!.toStringAsFixed(1)}m',
                  style: TextStyle(
                    fontSize: 12,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
          ],
          
          if (isSuspicious && result.suspiciousReasons != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alasan:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...result.suspiciousReasons!.map((reason) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.alertTriangle,
                          size: 12,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          reason,
                          style: TextStyle(
                            fontSize: 11,
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
