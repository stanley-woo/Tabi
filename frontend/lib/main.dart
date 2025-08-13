import 'package:flutter/material.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/screens/detailed_itinerary_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/create_itinerary_screen.dart';
import 'screens/map_picker_screen.dart';


class ProfileArgs {
  final String username;
  final String currentUser;
  const ProfileArgs(this.username, this.currentUser);
}

void main() {
  runApp(const Tabi());
}

class Tabi extends StatelessWidget {
  const Tabi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, title: 'Tabi', 
      theme: ThemeData(
        primaryColor: const Color(0xFF005B4F),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)
        ),
      // useMaterial3: true,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/create': (context) => const CreateItineraryScreen(),
        '/detail': (context) {
          final id = ModalRoute.of(context)!.settings.arguments as int;
          return DetailedItineraryScreen(id: id);
        },
        '/map_picker': (_) => const MapPickerScreen(),
        '/profile': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as ProfileArgs?;
          final username = args?.username ?? 'julieee_mun';
          final currentUser = args?.currentUser ?? 'julieee_mun';
          return ProfileScreen(username: username, currentUser: currentUser);
        },
      },
    );
  }
}