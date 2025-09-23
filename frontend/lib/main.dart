// lib/main.dart
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

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();


Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await AuthService.init();
  final authSore = AuthStore();
  await authSore.boot();
  runApp(
    ChangeNotifierProvider.value(
      value: authSore,
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

        // CHANGED: resolve currentUser from AuthStore; default to Julie only if missing
        '/profile': (context) {
          final auth = Provider.of<AuthStore?>(context, listen: false);
          final me = auth?.username ?? 'julieee_mun'; // fallback = Julie

          final Object? raw = ModalRoute.of(context)?.settings.arguments;
          if (raw is nav.ProfileArgs) {
            // If a target username was provided, view that profile.
            return ProfileScreen(username: raw.username, currentUser: me);
          }

          // No args? View *your own* profile (me vs Julie fallback).
          return ProfileScreen(username: me, currentUser: me);
        },
      },
    );
  }
}