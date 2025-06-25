import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final double bgSize = size.width * 1.1; // Increased background size
    final double logoSize = size.width * 0.45; // Increased logo size

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: SizedBox(
          width: bgSize,
          height: bgSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background Veggie Circle
              Image.asset(
                'assets/splash_background.png',
                width: bgSize,
                height: bgSize,
                fit: BoxFit.contain,
              ),

              // M Logo in Center
              Image.asset(
                'assets/Group.png',
                width: logoSize,
                height: logoSize,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
