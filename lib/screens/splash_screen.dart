import 'package:flutter/material.dart';
import 'package:renthouse/core/constants.dart';
import 'package:renthouse/screens/auth/login_screen.dart';
import 'package:renthouse/screens/dashboard_screen.dart';
import 'package:renthouse/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (_authService.isSignedIn()) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const DashboardScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image with blur effect
          Image.asset(
            AppConstants.splashImage,
            fit: BoxFit.cover,
          ),
          // Dark overlay for better text visibility
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.8),
                ],
                stops: [0.6, 1.0],
              ),
            ),
          ),
          // Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Icon with scale animation
              Transform.scale(
                scale: 1.2,
                child: Image.asset(
                  AppConstants.splashImage,
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 40),
              // App name with fade-in effect
              Opacity(
                opacity: 1.0,
                child: Text(
                  AppConstants.appName,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(2, 2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Tagline
              Opacity(
                opacity: 0.9,
                child: Text(
                  'Smart House Rental Solution',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 60),
              // Subtle loading indicator
              const Opacity(
                opacity: 0.7,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3.0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}