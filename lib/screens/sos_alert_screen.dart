import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Phase enum ────────────────────────────────────────────────────────────────

enum _SosPhase { confirm, active }

// ── Screen ────────────────────────────────────────────────────────────────────

class SosAlertScreen extends StatefulWidget {
  const SosAlertScreen({super.key});

  @override
  State<SosAlertScreen> createState() => _SosAlertScreenState();
}

class _SosAlertScreenState extends State<SosAlertScreen>
    with TickerProviderStateMixin {
  _SosPhase _phase = _SosPhase.confirm;

  String _category = 'Kriminal / Pembegalan';
  String? _alertId;
  Position? _position;
  bool _isLoading = false;

  Duration _elapsed = Duration.zero;
  Timer? _timer;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  static const _red    = Color(0xFFEF4444);
  static const _amber  = Color(0xFFF59E0B);
  static const _blue   = Color(0xFF3B82F6);
  static const _orange = Color(0xFFF97316);
  static const _purple = Color(0xFF8B5CF6);

  static const _categories = [
    {'label': 'Kriminal / Pembegalan', 'icon': LucideIcons.alertTriangle, 'color': _red},
    {'label': 'Darurat Medis',         'icon': LucideIcons.heartPulse,     'color': _blue},
    {'label': 'Kebakaran',             'icon': LucideIcons.flame,           'color': _orange},
    {'label': 'Lainnya',               'icon': LucideIcons.alertCircle,     'color': _purple},
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _activateSos() async {
    setState(() => _isLoading = true);
    HapticFeedback.heavyImpact();

    try {
      // Request & capture GPS
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
      }

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 6),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }

      // Fetch user name
      final user = FirebaseAuth.instance.currentUser;
      String userName = 'Anonim';
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        userName = doc.data()?['name'] as String? ?? 'Anonim';
      }

      // Save to Firestore
      final ref = await FirebaseFirestore.instance
          .collection('sos_alerts')
          .add({
        'userId':    user?.uid ?? 'anonymous',
        'userName':  userName,
        'category':  _category,
        'latitude':  pos?.latitude  ?? 0.0,
        'longitude': pos?.longitude ?? 0.0,
        'accuracy':  pos?.accuracy  ?? 0.0,
        'status':    'active',
        'createdAt': Timestamp.now(),
      });

      // Notify admins via Firestore (triggers local notification on admin devices)
      await FirebaseFirestore.instance.collection('sos_notifications').add({
        'alertId':   ref.id,
        'userName':  userName,
        'category':  _category,
        'latitude':  pos?.latitude  ?? 0.0,
        'longitude': pos?.longitude ?? 0.0,
        'createdAt': Timestamp.now(),
      });

      setState(() {
        _alertId  = ref.id;
        _position = pos;
        _phase    = _SosPhase.active;
        _isLoading = false;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal mengirim SOS: $e'),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _resolve(String status) async {
    _timer?.cancel();
    if (_alertId != null) {
      await FirebaseFirestore.instance
          .collection('sos_alerts')
          .doc(_alertId!)
          .update({'status': status, 'resolvedAt': Timestamp.now()});
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _call112() async {
    final uri = Uri.parse('tel:112');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  String get _elapsedStr {
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _red,
      body: SafeArea(
        child: _phase == _SosPhase.confirm
            ? _buildConfirm()
            : _buildActive(),
      ),
    );
  }

  // ── Confirm phase ────────────────────────────────────────────────────────────

  Widget _buildConfirm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        children: [
          // Close
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(LucideIcons.x, color: Colors.white, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Spacer(),

          // Pulsing SOS badge
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Center(
                child: Text(
                  'SOS',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Kirim Sinyal Darurat',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Koordinat GPS kamu akan otomatis dikirim.\nPilih jenis darurat, lalu geser tombol.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
          ),

          const Spacer(),

          // Category chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _categories.map((cat) {
              final sel = _category == cat['label'];
              return GestureDetector(
                onTap: () =>
                    setState(() => _category = cat['label'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: sel
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cat['icon'] as IconData,
                        size: 13,
                        color: sel
                            ? (cat['color'] as Color)
                            : Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sel
                              ? (cat['color'] as Color)
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Swipe button
          _isLoading
              ? const SizedBox(
                  height: 64,
                  child: Center(
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 3),
                  ),
                )
              : _SwipeToAlert(onTriggered: _activateSos),

          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup',
                style: TextStyle(color: Colors.white60, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  // ── Active phase ─────────────────────────────────────────────────────────────

  Widget _buildActive() {
    final lat = _position?.latitude.toStringAsFixed(6)  ?? '—';
    final lng = _position?.longitude.toStringAsFixed(6) ?? '—';
    final acc = _position != null
        ? '±${_position!.accuracy.toInt()} m'
        : '—';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        children: [
          // Badge
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Center(
                child: Text(
                  'SOS',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'SINYAL DARURAT AKTIF',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),

          // Timer
          Text(
            _elapsedStr,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w200,
              color: Colors.white,
              letterSpacing: 4,
            ),
          ),

          const Spacer(),

          // Info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(LucideIcons.tag,    'Jenis',     _category),
                const SizedBox(height: 10),
                _infoRow(LucideIcons.mapPin, 'Latitude',  lat),
                const SizedBox(height: 4),
                _infoRow(LucideIcons.mapPin, 'Longitude', lng),
                const SizedBox(height: 4),
                _infoRow(LucideIcons.radio, 'Akurasi', acc),
              ],
            ),
          ),

          const Spacer(),

          // Call 112
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _call112,
              icon: const Icon(LucideIcons.phone, size: 20),
              label: const Text(
                'Hubungi 112',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Situasi aman
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _resolve('resolved'),
              icon: const Icon(LucideIcons.checkCircle, size: 20),
              label: const Text(
                'Situasi Sudah Aman',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // False alarm
          TextButton(
            onPressed: _showCancelConfirm,
            child: const Text(
              'Batalkan (false alarm)',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, size: 13, color: Colors.white60),
          const SizedBox(width: 8),
          Text('$label: ',
              style:
                  const TextStyle(fontSize: 12, color: Colors.white60)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  void _showCancelConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(LucideIcons.alertTriangle, color: _amber, size: 20),
          SizedBox(width: 8),
          Text('Batalkan SOS?'),
        ]),
        content: const Text(
            'Tandai sebagai false alarm dan hentikan sinyal darurat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _resolve('false_alarm');
            },
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }
}

// ── Swipe-to-Alert Widget ─────────────────────────────────────────────────────

class _SwipeToAlert extends StatefulWidget {
  final VoidCallback onTriggered;
  const _SwipeToAlert({required this.onTriggered});

  @override
  State<_SwipeToAlert> createState() => _SwipeToAlertState();
}

class _SwipeToAlertState extends State<_SwipeToAlert>
    with SingleTickerProviderStateMixin {
  static const double _thumbSize  = 58.0;
  static const double _trackH     = 64.0;
  static const double _pad        = 4.0;
  static const double _threshold  = 0.83;

  double _pos       = 0;
  bool   _triggered = false;

  late final AnimationController _snapCtrl;
  late final Animation<double>   _snapAnim;

  @override
  void initState() {
    super.initState();
    _snapCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _snapAnim = Tween<double>(begin: 0, end: 0)
        .animate(CurvedAnimation(parent: _snapCtrl, curve: Curves.easeOut));
    _snapCtrl.addListener(() => setState(() => _pos = _snapAnim.value));
  }

  @override
  void dispose() {
    _snapCtrl.dispose();
    super.dispose();
  }

  void _onUpdate(DragUpdateDetails d, double trackW) {
    if (_triggered) return;
    setState(() {
      _pos = (_pos + d.delta.dx).clamp(0.0, trackW);
    });
    if (_pos >= trackW * _threshold) {
      _triggered = true;
      HapticFeedback.heavyImpact();
      widget.onTriggered();
    }
  }

  void _onEnd(double trackW) {
    if (_triggered) return;
    _snapAnim = Tween<double>(begin: _pos, end: 0)
        .animate(CurvedAnimation(parent: _snapCtrl, curve: Curves.easeOut));
    _snapCtrl
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final trackW = constraints.maxWidth - _pad * 2 - _thumbSize;
      final progress =
          trackW > 0 ? (_pos / trackW).clamp(0.0, 1.0) : 0.0;

      return Container(
        height: _trackH,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(_trackH / 2),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.45), width: 1.5),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // progress fill
            Container(
              width: _pad + _thumbSize + _pos,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius:
                    BorderRadius.circular(_trackH / 2),
              ),
            ),
            // label
            Center(
              child: Opacity(
                opacity: (1 - progress * 2.2).clamp(0.0, 1.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Geser untuk kirim SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(LucideIcons.chevronsRight,
                        size: 18, color: Colors.white70),
                  ],
                ),
              ),
            ),
            // thumb
            Positioned(
              left: _pad + _pos,
              child: GestureDetector(
                onHorizontalDragUpdate: (d) => _onUpdate(d, trackW),
                onHorizontalDragEnd: (_) => _onEnd(trackW),
                child: Container(
                  width: _thumbSize,
                  height: _thumbSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    _triggered
                        ? LucideIcons.check
                        : LucideIcons.chevronsRight,
                    color: const Color(0xFFEF4444),
                    size: 26,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
