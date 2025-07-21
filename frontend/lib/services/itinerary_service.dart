import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/itinerary.dart';

class ItineraryService {
  static const _base = 'http://localhost:8000';

  static Future<Itinerary> fetchDetail(int id) async {
    final resp = await http.get(Uri.parse('$_base/itineraries/$id'));
    if (resp.statusCode != 200) {
      throw Exception('Failed to load itinerary.');
    }
    return Itinerary.fromJson(jsonDecode(resp.body));
  }

  static Future<List<Itinerary>> fetchList() async {
    final resp = await http.get(Uri.parse('$_base/itineraries/'));
    if (resp.statusCode != 200) {
      throw Exception('Failed to load itineraries');
    }
    final List<dynamic> body = jsonDecode(resp.body);
    return body.map((j) => Itinerary.fromJson(j)).toList();
  }
}