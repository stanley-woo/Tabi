import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/itinerary.dart';

class ProfileService {
  static const _base = 'http://localhost:8000';

  static Future<List<Itinerary>> fetchUserItineraries(String username) async {
    final resp = await http.get(Uri.parse('$_base/users/$username/itineraries'));
    if (resp.statusCode != 200) {
      throw Exception('Failed to load user itineraries');
    }
    final list = jsonDecode(resp.body) as List<dynamic>;
    return list.map((j) => Itinerary.fromJson(j)).toList();
  }
}