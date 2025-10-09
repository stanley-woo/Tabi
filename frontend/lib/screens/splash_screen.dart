import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';

import 'package:frontend/screens/reset_password_screen.dart';
import '../state/auth_store.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Check for the initial link that launched the app
    final initialUri = await _appLinks.getInitialLink();

    if (initialUri != null) {
      // If a deep link is found, process it immediately
      _processLink(initialUri);
    } else {
      // If no deep link, proceed with normal app start after a short delay
      // to allow the user to see the splash screen.
      Timer(const Duration(seconds: 2), _initApp);
    }

    // Listen for any further links that come in while the app is running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _processLink(uri);
    });
  }
  
  void _processLink(Uri uri) {
    if (!mounted) return;
    // We expect links like "tabi://reset-password?token=..."
    if (uri.scheme == 'tabi' && uri.host == 'reset-password') {
      final token = uri.queryParameters['token'];
      if (token != null) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(token: token),
        ));
      }
    }
  }

  void _initApp() {
    if (!mounted) return;
    // This is the original navigation logic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthStore>(context, listen: false);
      if (auth.isLoggedIn) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- YOUR UI IS PRESERVED HERE ---
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal, Colors.tealAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            ),
        ),
        child: Center(
          child: Image.asset(
            'assets/tabi_logo.png',
            width: 510,
            height: 510,
          ),
        ),
      ),
    );
  }
}