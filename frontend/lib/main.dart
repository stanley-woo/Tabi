import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';

import 'package:frontend/services/auth_service.dart';
import 'state/auth_store.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/detailed_itinerary_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/create_itinerary_screen.dart';
import 'screens/map_picker_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/verify_email_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'navigation/profile_args.dart' as nav;
import 'navigation/create_itinerary_args.dart';
import 'package:frontend/services/api.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class DeepLinkHandler {
  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _linkSubscription;

  static void initialize() {
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
      // Add delay to ensure app is fully initialized
      Future.delayed(const Duration(milliseconds: 3000), () {
        _handleDeepLink(uri);
      });
    });
  }

  static void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'tabi' && uri.host == 'reset-password') {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        _navigateToResetPassword(token);
      }
    } else if (uri.scheme == 'tabi' && uri.host == 'verify-email') {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        _navigateToVerifyEmail(token);
      }
    }
  }

  static void _navigateToResetPassword(String token) {
    _attemptNavigation(() {
      final context = _getCurrentContext();
      if (context != null) {
        try {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(token: token),
              settings: RouteSettings(arguments: token),
            ),
            (route) => false,
          );
          return true;
        } catch (e) {
          return false;
        }
      }
      return false;
    });
  }

  static void _navigateToVerifyEmail(String token) {
    _attemptNavigation(() {
      final context = _getCurrentContext();
      if (context != null) {
        try {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => VerifyEmailScreen()),
            (route) => false,
          );
          // Auto-verify after navigation
          Future.delayed(const Duration(milliseconds: 2000), () {
            _verifyEmailWithToken(token);
          });
          return true;
        } catch (e) {
          return false;
        }
      }
      return false;
    });
  }

  static void _verifyEmailWithToken(String token) async {
    try {
      await AuthService.verifyEmail(token);
      
      final context = _getCurrentContext();
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to login after verification
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        });
      }
    } catch (e) {
      final context = _getCurrentContext();
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static void _attemptNavigation(bool Function() navigationFunction) {
    // Try immediate navigation
    if (navigationFunction()) {
      return;
    }
    
    // Try with increasing delays
    final delays = [500, 1000, 2000, 3000];
    for (int i = 0; i < delays.length; i++) {
      Future.delayed(Duration(milliseconds: delays[i]), () {
        if (navigationFunction()) {
          return;
        }
      });
    }
  }

  static BuildContext? _getCurrentContext() {
    return navigatorKey.currentContext;
  }

  static void dispose() {
    _linkSubscription?.cancel();
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize auth service (validates stored token) with timeout
  try {
    await AuthService.init().timeout(const Duration(seconds: 5));
  } catch (e) {
    // Silent fallback
  }
  
  // Create auth store
  final authStore = AuthStore();
  
  // Set up global 401 handler
  ApiClient.instance.onAuthenticationFailed = () async {
    await authStore.logout();
  };
  
  // Boot auth store (fetches user info if token is valid) with timeout
  try {
    await authStore.boot().timeout(const Duration(seconds: 5));
  } catch (e) {
    // Silent fallback
  }
  
  // Initialize global deep link handler
  DeepLinkHandler.initialize();
  
  runApp(
    ChangeNotifierProvider.value(
      value: authStore,
      child: const Tabi(),
    ),
  );
}

class Tabi extends StatelessWidget {
  const Tabi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Tabi',
      navigatorObservers: [routeObserver],
      theme: ThemeData(
        primaryColor: const Color(0xFF005B4F),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if(settings.name == '/create') {
          final args = settings.arguments as CreateItineraryArgs?;
          return MaterialPageRoute(builder: (_) => CreateItineraryScreen(template: args?.template), settings: settings);
        }
        return null;
      },
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/detail': (context) {
          final id = ModalRoute.of(context)!.settings.arguments as int;
          return DetailedItineraryScreen(id: id);
        },
        '/map_picker': (_) => const MapPickerScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
        '/verify-email': (context) => const VerifyEmailScreen(),
        '/change-password': (context) => const ChangePasswordScreen(),
        '/reset-password': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is String) {
            return ResetPasswordScreen(token: args);
          }
          return const ResetPasswordScreen(token: '');
        },
        '/profile': (context) {
          final Object? raw = ModalRoute.of(context)?.settings.arguments;
          if (raw is nav.ProfileArgs) {
            // If a target username was provided, view that profile.
            return ProfileScreen(username: raw.username);
          }

          // No args? View *your own* profile.
          final auth = Provider.of<AuthStore?>(context, listen: false);
          final me = auth?.username;
          // If for some reason we're not logged in, redirect to login
          if (me == null) return const LoginScreen();
          return ProfileScreen(username: me);
        },
      },
    );
  }
}