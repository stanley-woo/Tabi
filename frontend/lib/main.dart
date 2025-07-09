import 'package:flutter/material.dart';
import 'demo/detailed_itinerary_demo.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';

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
        '/demo': (context) => const DetailedItineraryDemo(),
      },
    );
  }
}