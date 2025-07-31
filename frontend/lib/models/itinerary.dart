import 'itinerary_block.dart';
import 'day_group.dart';

class Itinerary {
  final int id;
  final String title;
  final String description;
  final List<String>? tags;
  final String slug;
  final List<ItineraryBlock> blocks;
  final List<DayGroup> days;

  Itinerary({
    required this.id,
    required this.title,
    required this.description,
    this.tags,
    required this.slug,
    this.blocks = const [],
    this.days = const []
  });

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      tags: (json['tags'] as List<dynamic>?) ?.map((t) => t as String).toList(),
      slug: json['slug'],
      blocks: (json['blocks'] as List<dynamic>?)?.map((b) => ItineraryBlock.fromJson(b)).toList() ?? [],
      days: (json['days'] as List<dynamic>?)?.map((e) => DayGroup.fromJson(e as Map<String, dynamic>)).toList() ?? []
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'tags': tags,
      'slug': slug,
      'blocks': blocks.map((b) => b.toJson()).toList(),
      'days': days.map((d) => d.toJson()).toList()
    };
  }

}