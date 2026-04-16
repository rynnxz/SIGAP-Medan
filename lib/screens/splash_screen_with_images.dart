import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'home_screen_firestore.dart';
import 'dinas_screen.dart';

/// Splash Screen dengan support untuk logo images
/// Taruh logo di assets/images/ dan uncomment di pubspec.yaml
class SplashScreenWithImages extends StatefulWidget {
  final ThemeMode currentTheme;
  final Function(ThemeMode) onThemeChanged;

  const SplashScreenWithImages({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  State<SplashScreenWithImages> createState() => _SplashScreenWithImagesState();
}

class _SplashScreenWithImagesState extends State<SplashScreenWithImages>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await Future.delayed(const Duration(milliseconds: 3000));

      final authService = AuthService();
      User? user = authService.currentUser;

      if (user == null) {
        await authService.signInAnonymously();
        user = authService.currentUser;
      }

      // Check accountType for non-anonymous users
      Widget destination = HomeScreenFirestore(
        onThemeChanged: widget.onThemeChanged,
      );

      if (user != null && !user.isAnonymous) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          final accountType =
              doc.data()?['accountType'] as String? ?? 'user';
          if (accountType == 'dinas') {
            destination = const DinasScreen();
          }
        } catch (_) {
          // fallback to HomeScreenFirestore on error
        }
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                destination,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      // ...
    }
  }
}