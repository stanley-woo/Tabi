import 'dart:convert';

class DayGroup {
  final int id;
  final int itineraryId;
  final DateTime date;
  final int order;
  final String? title;

  DayGroup({
    required this.id,
    required this.itineraryId,
    required this.date,
    required this.order,
    this.title
  });

  factory DayGroup.fromJson(Map<String, dynamic> json) {
    return DayGroup(
      id: json['id'] as int, 
      itineraryId: json['itinerary_id'] as int, 
      date: DateTime.parse(json['date'] as String), 
      order: json['order'] as int,
      title: json['title'] as String?
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id' : id,
      'itinerary_id': itineraryId,
      'date': date.toIso8601String().substring(0,10),
      'order': order,
      'title': title
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}


