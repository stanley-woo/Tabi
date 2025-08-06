import 'day_group.dart';

class Itinerary {
  final int id;
  final String title;
  final String description;
  final String slug;
  final int creatorId;
  final List<String>? tags;
  final List<DayGroup> days;

  Itinerary({
    required this.id,
    required this.title,
    required this.description,
    required this.slug,
    required this.creatorId,
    this.tags,
    this.days = const [],
  });

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      slug: json['slug'] as String,
      creatorId: json['creator_id'] as int,
      tags: (json['tags'] as List<dynamic>?)
          ?.map((t) => t as String)
          .toList(),
      days: (json['days'] as List<dynamic>?)
          ?.map((d) => DayGroup.fromJson(d as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}