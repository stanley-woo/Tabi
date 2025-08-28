// lib/services/day_group_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api.dart';
import '../models/day_group.dart';

class DayGroupService {
  /// Fetch all day-groups for a given itinerary.
  static Future<List<DayGroup>> fetchDayGroups(int itineraryId) async {
    final uri = Uri.parse('$baseUrl/itineraries/$itineraryId/days');
    final resp = await http.get(uri);
    final body = jsonOrThrow(resp) as List<dynamic>;
    return body.map((e) => DayGroup.fromJson(e)).toList();
  }

  /// Create a new day-group (server will still store max+1, but schema requires `order`)
  static Future<DayGroup> createDayGroup({
    required int itineraryId,
    required DateTime date,
    String? title,
    required int order, // <-- add this
  }) async {
    final uri = Uri.parse('$baseUrl/itineraries/$itineraryId/days');
    final payload = {
      'date': date.toIso8601String().substring(0, 10),
      'order': order, // <-- include this
      if (title != null) 'title': title,
    };
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    final body = jsonOrThrow(resp) as Map<String, dynamic>;
    return DayGroup.fromJson(body);
  }


  static Future<DayGroup> updateDayGroup({
    required int dayId,
    required DateTime date,
    String? title,
  }) async {
    final uri = Uri.parse('$baseUrl/days/$dayId'); // <-- fix path
    final resp = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'date': date.toIso8601String().substring(0, 10),
        if (title != null) 'title': title,
      }),
    );
    final body = jsonOrThrow(resp) as Map<String, dynamic>;
    return DayGroup.fromJson(body);
  }


  /// Delete a day-group.
  static Future<void> deleteDayGroup({
    required int itineraryId,
    required int dayGroupId,
  }) async {
    final uri = Uri.parse('$baseUrl/itineraries/$itineraryId/days/$dayGroupId');
    final resp = await http.delete(uri);
    jsonOrThrow(resp); // expects 204; helper will throw if not 2xx
  }

  /// Reorder day-groups by new list of IDs.
  static Future<List<DayGroup>> reorderDayGroups({
    required int itineraryId,
    required List<int> orderedIds,
  }) async {
    final uri = Uri.parse('$baseUrl/itineraries/$itineraryId/days/reorder');
    final resp = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(orderedIds),
    );
    final body = jsonOrThrow(resp) as List<dynamic>;
    return body.map((e) => DayGroup.fromJson(e)).toList();
  }
}