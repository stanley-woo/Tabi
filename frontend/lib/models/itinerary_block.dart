class ItineraryBlock {
  final int id;
  final int dayGroupId;
  final int order;
  final String type;
  final String content;

  ItineraryBlock({
    required this.id,
    required this.dayGroupId,
    required this.order,
    required this.type,
    required this.content,
  });

  factory ItineraryBlock.fromJson(Map<String, dynamic> json) {
    return ItineraryBlock(
      id: json['id'] as int,
      dayGroupId: json['day_group_id'] as int,
      order: json['order'] as int,
      type: json['type'] as String,
      content: json['content'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'day_group_id': dayGroupId,
        'order': order,
        'type': type,
        'content': content,
      };
}


