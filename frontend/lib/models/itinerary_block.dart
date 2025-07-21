class ItineraryBlock {
  final int id;
  final int order;
  final String type;
  final String content;

  ItineraryBlock({
    required this.id,
    required this.order,
    required this.type,
    required this.content
  });

  factory ItineraryBlock.fromJson(Map<String, dynamic> json) {
    return ItineraryBlock(
      id: json['id'],
      order: json['order'],
      type: json['type'],
      content: json['content']
    );
  }
}


