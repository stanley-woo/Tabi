import 'itinerary_block.dart';

class Itinerary {
  final int id;
  final String title;
  final String description;
  final List<String>? tags;
  final String slug;
  final List<ItineraryBlock> blocks;

  Itinerary({
    required this.id,
    required this.title,
    required this.description,
    this.tags,
    required this.slug,
    this.blocks = const [],
  });

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      tags: (json['tags'] as List<dynamic>?)
          ?.map((t) => t as String)
          .toList(),
      slug: json['slug'],
      blocks: (json['blocks'] as List<dynamic>?)
          ?.map((b) => ItineraryBlock.fromJson(b))
          .toList() ??
          [],
    );
  }
}