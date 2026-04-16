import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_config_service.dart';

class AppGate extends StatefulWidget {
  final Widget child;
  const AppGate({super.key, required this.child});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  StreamSubscription<AppConfig>? _sub;
  bool _loading = true;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    _sub = AppConfigService.stream().listen(_onConfig);
  }

  void _onConfig(AppConfig cfg) {
    if (!mounted) return;
    setState(() => _loading = false);

    final status = cfg.gateStatus;
    if (status == AppGateStatus.killed || status == AppGateStatus.needsUpdate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _dialogShown) return;
        _dialogShown = true;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withOpacity(0.75),
          useRootNavigator: true,
          builder: (_) => PopScope(
            canPop: false,
            child: status == AppGateStatus.killed
                ? _KillModal(message: cfg.killMessage)
                : _UpdateModal(
                    message: cfg.updateMessage,
                    updateUrl: cfg.updateUrl,
                    minVersion: cfg.minVersion,
                  ),
          ),
        ).then((_) => _dialogShown = false);
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _SplashScreen();
    return widget.child;
  }
}

// ── Splash while loading ────────────────────────────────────────────────────

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF111827),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SigapLogo(),
            SizedBox(height: 32),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Color(0xFF10B981),
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hard Update Modal ───────────────────────────────────────────────────────

class _UpdateModal extends StatelessWidget {
  final String message;
  final String updateUrl;
  final String minVersion;

  const _UpdateModal({
    required this.message,
    required this.updateUrl,
    required this.minVersion,
  });

  Future<void> _openStore() async {
    if (updateUrl.isEmpty) return;
    final uri = Uri.tryParse(updateUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          width: 1.5),
                    ),
                    child: const Icon(LucideIcons.refreshCw,
                        size: 32, color: Color(0xFF10B981)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Pembaruan Diperlukan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Min $minVersion  •  Versimu $kAppVersion',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF38383A)),
            if (updateUrl.isNotEmpty)
              TextButton(
                onPressed: _openStore,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  minimumSize: const Size(double.infinity, 0),
                ),
                child: const Text(
                  'Perbarui Sekarang',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              )
            else
              const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Kill Switch Modal ───────────────────────────────────────────────────────

class _KillModal extends StatelessWidget {
  final String message;
  const _KillModal({required this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFFEF4444).withOpacity(0.3),
                      width: 1.5),
                ),
                child: const Icon(LucideIcons.shieldOff,
                    size: 32, color: Color(0xFFEF4444)),
              ),
              const SizedBox(height: 20),
              const Text(
                'Akses Dinonaktifkan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'SIGAP MEDAN — OFFLINE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEF4444),
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8E8E93),
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 24),
              const _SigapLogo(size: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared logo mark ────────────────────────────────────────────────────────

class _SigapLogo extends StatelessWidget {
  final double size;
  const _SigapLogo({this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.mapPin,
            size: size * 0.7, color: const Color(0xFF10B981)),
        const SizedBox(height: 4),
        Text(
          'SIGAP MEDAN',
          style: TextStyle(
            fontSize: size * 0.28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        Text(
          'v$kAppVersion',
          style: TextStyle(
            fontSize: size * 0.2,
            color: const Color(0xFF6B7280),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
