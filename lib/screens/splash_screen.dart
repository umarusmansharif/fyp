import 'package:flutter/material.dart';
import 'package:renthouse/screens/auth/login_screen.dart';
import 'package:renthouse/screens/dashboard_screen.dart';
import 'package:renthouse/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 3));

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
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Top Section - Original Splash Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: screenHeight * 0.55,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                child: Image.asset(
                  'assets/images/splash.jpg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          ),

          // Bottom Container - Enhanced Design
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: screenHeight * 0.50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 40,
                    offset: const Offset(0, -15),
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // Modern Animated Dot Loader - 4 dots horizontal left-to-right
                    SizedBox(
                      height: 20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          return AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              // Calculate staggered animation for each dot
                              final staggeredValue = (_pulseController.value + (index * 0.25)) % 1.0;
                              
                              // Color transition: Dark Blue <-> White
                              final isPrimary = staggeredValue > 0.5;
                              final dotColor = isPrimary ? Color(0xFF1A237E) : Colors.white;
                              final shadowOpacity = isPrimary ? 0.3 : 0.1;

                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 100),
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: dotColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Color(0xFF1A237E),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF1A237E).withOpacity(shadowOpacity),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Loading Text - Enhanced visibility
                    Text(
                      'Please wait... loading your experience',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        height: 1.4,
                      ),
                    ),

                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}