// lib/services/day_group_service.dart
import 'dart:convert';
import 'api.dart';
import '../models/day_group.dart';

class DayGroupService {
  static final _api = ApiClient.instance;
  /// Fetch all day-groups for a given itinerary.
  static Future<List<DayGroup>> fetchDayGroups(int itineraryId) async {
    final body = await _api.get('/itineraries/$itineraryId/days') as List<dynamic>;
    return body.map((e) => DayGroup.fromJson(e)).toList();
  }

  /// Create a new day-group (server will still store max+1, but schema requires `order`)
  static Future<DayGroup> createDayGroup({
    required int itineraryId,
    required DateTime date,
    String? title,
    required int order
  }) async {
    final payload = {
      'date': date.toIso8601String().substring(0, 10),
      'order': order,
      if (title != null) 'title': title,
    };
    final body = await _api.post(
      '/itineraries/$itineraryId/days',
      body: payload,
    ) as Map<String, dynamic>;
    return DayGroup.fromJson(body);
  }


  static Future<DayGroup> updateDayGroup({
    required int itineraryId,
    required int dayId,
    required DateTime date,
    String? title,
  }) async {
    final payload = { 
      'date': date.toIso8601String().substring(0, 10),
      if (title != null) 'title': title
    };

    final body = await _api.patch('/itineraries/$itineraryId/days/$dayId', body: payload) as Map<String, dynamic>;
    return DayGroup.fromJson(body);
  }


  /// Delete a day-group.
  static Future<void> deleteDayGroup({
    required int itineraryId,
    required int dayGroupId,
  }) async {
    await _api.delete_('/itineraries/$itineraryId/days/$dayGroupId');
  }

  /// Reorder day-groups by new list of IDs.
  static Future<List<DayGroup>> reorderDayGroups({
    required int itineraryId,
    required List<int> orderedIds,
  }) async {
    final body = await _api.patch(
      '/itineraries/$itineraryId/days/reorder',
      body: orderedIds,
    ) as List<dynamic>;
    return body.map((e) => DayGroup.fromJson(e)).toList();
  }
}