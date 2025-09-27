import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/services/auth_service.dart';
import 'state/auth_store.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/detailed_itinerary_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/create_itinerary_screen.dart';
import 'screens/map_picker_screen.dart';
import 'navigation/profile_args.dart' as nav;
import 'navigation/create_itinerary_args.dart';
import 'package:frontend/services/api.dart';
import 'package:flutter/foundation.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize auth service (validates stored token)
  await AuthService.init();
  
  // Create auth store
  final authStore = AuthStore();
  
  // Set up global 401 handler
  ApiClient.instance.onAuthenticationFailed = () {
    if (kDebugMode) {
      print('[Main] Global auth failure detected, logging out...');
    }
    authStore.logout();
  };
  
  // Boot auth store (fetches user info if token is valid)
  await authStore.boot();
  
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

        // --- MODIFIED SECTION ---
        // The currentUser is now resolved from AuthStore inside ProfileScreen,
        // so we no longer need to pass it as an argument here.
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