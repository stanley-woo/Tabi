import 'package:flutter/material.dart';
import 'demo/detailed_itinerary_demo.dart';

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
    home: const DetailedItineraryDemo(),);
  }
}