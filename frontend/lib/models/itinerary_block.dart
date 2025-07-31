class ItineraryBlock {
  final int id;
  final int itineraryId;
  final int? dayGroupId;
  final int order;
  final String type;
  final String content;

  ItineraryBlock({
    required this.id,
    required this.itineraryId,
    this.dayGroupId,
    required this.order,
    required this.type,
    required this.content,
  });

  factory ItineraryBlock.fromJson(Map<String, dynamic> json) => ItineraryBlock(
    id: json['id'] as int,
    itineraryId: json['itinerary_id'] as int,
    dayGroupId: json['day_group_id'] as int?,  // ensure backend includes this field
    order: json['order'] as int,
    type: json['type'] as String,
    content: json['content'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'itinerary_id': itineraryId,
    'day_group_id': dayGroupId,
    'order': order,
    'type': type,
    'content': content,
  };
}


