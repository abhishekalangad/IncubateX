import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'landing_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(context, _createRippleRoute());
    });
  }

  PageRouteBuilder _createRippleRoute() {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => const LandingPage(),
      transitionDuration: const Duration(milliseconds: 1000),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = screenWidth * 0.35;
    final fontSize = screenWidth * 0.08;
    final taglineFontSize = screenWidth * 0.045;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 18, 18), // 🔥 Changed from gradient to solid black
      body: Center(
        child: BounceInDown(
          duration: const Duration(milliseconds: 1500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Hero(
                tag: 'logo',
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 18, 18, 18),
                        blurRadius: 30,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: Image.asset(
                    'assets/lead-logo.png',
                    width: logoSize,
                    height: logoSize,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // App Name
              FadeInUp(
                duration: const Duration(milliseconds: 1200),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          blurRadius: 8,
                          color: Colors.black.withOpacity(0.4),
                          offset: const Offset(1, 2),
                        )
                      ],
                    ),
                    children: const [
                      TextSpan(
                        text: 'Incubate',
                        style: TextStyle(color: Colors.white),
                      ),
                      TextSpan(
                        text: 'X',
                        style: TextStyle(color: Color(0xFF00A2FF)),
                      ),
                    ],
                  ),
                ),
              ),

              // Tagline
              const SizedBox(height: 10),
              FadeInUp(
                duration: const Duration(milliseconds: 1500),
                child: Text(
                  'Empowering E-LEAD Innovations',
                  style: TextStyle(
                    fontSize: taglineFontSize,
                    fontStyle: FontStyle.italic,
                    color: Colors.white70,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
