import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';

import 'package:frontend/screens/reset_password_screen.dart';
import '../state/auth_store.dart';

// Temporary flag: enable after Apple associated domains are configured
const bool kEnableDeepLinks = true;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  bool _navigated = false;
  Timer? _safetyTimer;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _safetyTimer?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    if (!kEnableDeepLinks) {
      Timer(const Duration(seconds: 1), _initApp);
      return;
    }

    _appLinks = AppLinks();

    _safetyTimer = Timer(const Duration(seconds: 2), () {
      if (!_navigated) _initApp();
    });

    Uri? initialUri;
    try {
      initialUri = await _appLinks.getInitialAppLink().timeout(const Duration(milliseconds: 800));
    } catch (_) {
      initialUri = null;
    }

    if (initialUri != null && _handleDeepLink(initialUri)) return;

    _linkSubscription = _appLinks.uriLinkStream.listen(_handleDeepLink);
  }
  
  bool _handleDeepLink(Uri uri) {
    print('Handling deep link: $uri');
    if (!mounted) return false;
    if (uri.scheme == 'tabi' && uri.host == 'reset-password') {
      final token = uri.queryParameters['token'];
      if (token == null || token.isEmpty) return false;

      // One-shot: cancel timers/streams and mark as navigated
      _safetyTimer?.cancel();
      _linkSubscription?.cancel();
      _navigated = true;

      // Defer navigation until after the first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ResetPasswordScreen(token: token)),
        );
      });
      return true;
    }
    return false;
  }

  void _initApp() {
    if (!mounted || _navigated) return;
    _navigated = true;
    _safetyTimer?.cancel();
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