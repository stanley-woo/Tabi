import 'package:flutter/material.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'demo/detailed_itinerary_demo.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/create_itinerary_screen.dart';


void main() {
  runApp(const Tabi());
}

class Tabi extends StatelessWidget {
  const Tabi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, title: 'Tabi', 
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
      // useMaterial3: true,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/create': (context) => const CreateItineraryScreen(),
        '/detail': (context) {
          final id = ModalRoute.of(context)!.settings.arguments as int;
          return DetailedItineraryDemo(id: id);
        },
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}