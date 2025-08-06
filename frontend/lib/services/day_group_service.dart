import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/day_group.dart';

class DayGroupService {
  static const _base = 'http://localhost:8000';

  /// Fetch all day-groups for a given itinerary.
  static Future<List<DayGroup>> fetchDayGroups(int itineraryId) async {
    final uri = Uri.parse('$_base/itineraries/$itineraryId/days');
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Failed to load day groups');
    }
    final List<dynamic> body = jsonDecode(resp.body);
    return body.map((e) => DayGroup.fromJson(e)).toList();
  }

  /// Create a new day-group (server auto-assigns its order).
  static Future<DayGroup> createDayGroup({required int itineraryId, required DateTime date, String? title, required int order}) async {
    final uri = Uri.parse('$_base/itineraries/$itineraryId/days');
    final payload = {
      'date': date.toIso8601String().substring(0, 10),
      'order': order,
      if (title != null) 'title': title,
    };
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (resp.statusCode != 201) {
      throw Exception('Failed to create day group');
    }
    return DayGroup.fromJson(jsonDecode(resp.body));
  }

  /// Delete a day-group.
  static Future<void> deleteDayGroup({required int itineraryId,required int dayGroupId}) async {
    final uri = Uri.parse('$_base/itineraries/$itineraryId/days/$dayGroupId');
    final resp = await http.delete(uri);
    if (resp.statusCode != 204) {
      throw Exception('Failed to delete day group');
    }
  }

  /// Reorder day-groups by supplying a new list of IDs.
  static Future<List<DayGroup>> reorderDayGroups({required int itineraryId,required List<int> orderedIds}) async {
    final uri = Uri.parse('$_base/itineraries/$itineraryId/days/reorder');
    final resp = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(orderedIds),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to reorder day groups');
    }
    final List<dynamic> body = jsonDecode(resp.body);
    return body.map((e) => DayGroup.fromJson(e)).toList();
  }
}