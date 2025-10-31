import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_store.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;
  Timer? _safetyTimer;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    // Deep links are now handled globally in main.dart
    // Just initialize the app normally
    Timer(const Duration(seconds: 1), _initApp);
    
    // Safety timeout - if _initApp doesn't work, force navigation after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted && !_navigated) {
        _navigated = true;
        try {
          Navigator.of(context).pushReplacementNamed('/login');
        } catch (e) {
          // Silent fallback
        }
      }
    });
  }
  

  void _initApp() async {
    if (!mounted || _navigated) return;
    _navigated = true;
    _safetyTimer?.cancel();
    
    try {
      final auth = Provider.of<AuthStore>(context, listen: false);
      
      if (auth.isLoggedIn) {
        // Test if the token is actually valid by making a quick API call
        try {
          await auth.testTokenValidity();
          Navigator.of(context).pushReplacementNamed('/home');
        } catch (e) {
          await auth.clearAllData();
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      // Fallback navigation
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          try {
            Navigator.of(context).pushReplacementNamed('/login');
          } catch (e2) {
            // Silent fallback
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Image.asset(
          'assets/splash/Tabi-splash.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}