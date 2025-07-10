class Itinerary {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final int likes;
  final int saves;
  final int forks;

  Itinerary({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.likes = 0,
    this.saves = 0,
    this.forks = 0,
  });
}