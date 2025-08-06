import 'itinerary_block.dart';

class DayGroup {
  final int id;
  final DateTime date;
  final int order;
  final String? title;
  final List<ItineraryBlock> blocks;

  DayGroup({
    required this.id,
    required this.date,
    required this.order,
    this.title,
    this.blocks = const [],
  });

  factory DayGroup.fromJson(Map<String, dynamic> json) {
    return DayGroup(
      id: json['id'] as int,
      date: DateTime.parse(json['date'] as String),
      order: json['order'] as int,
      title: json['title'] as String?,
      blocks: (json['blocks'] as List<dynamic>?)
            ?.map((b) => ItineraryBlock.fromJson(b as Map<String, dynamic>))
            .toList() ??
          [],
    );
  }
}


