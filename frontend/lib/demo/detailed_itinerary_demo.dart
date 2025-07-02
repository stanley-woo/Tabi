import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DetailedItineraryDemo extends StatelessWidget {
  const DetailedItineraryDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Itinerary Detail')), 
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A Day in Ginzan Onsen',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Explore Scenic Hot Spring Streets, Charming Cafes, and Historical Spots In One Day.',
            style: TextStyle(fontSize: 16),
          ),
          const Divider(height: 32),

          // Morning
          sectionHeader('Morning: Shirogane Falls & Foot Bath'),
          imageWithCaption('assets/shirogane.jpg', 'Shirogane Falls - Scenic Walk'),
          const SizedBox(height: 8),
          const Text(
            'Start Your Morning With A Relaxing Walk To Shirogane Falls, Followed By A Free Foot Bath Nearby.',
          ),
          const SizedBox(height: 12),
          infoCard(title: 'Waraku Foot Bath', subtitle: 'Ginzan Onsen, Yamagata', trailing: '06:00 - 22:00',),

          const Divider(height: 32),

          // Afternoon
          sectionHeader('Afternoon: Cafe & Lunch'),
          imageWithCaption('assets/cafe.jpg', 'Retro cafe with a view'),
          const SizedBox(height: 8),
          const Text(
            'Enjoy lunch at a retro cafe. Try homemade soba and Japanese sweets!',
          ),

          const Divider(height: 32),

          // Evening
          sectionHeader('Evening: Lantern-lit Walk'),
          imageWithCaption('assets/lantern.jpg', 'Ginzan streets at night'),
          const SizedBox(height: 8),
          const Text(
            'Walk through gas-lit alleys and take in the nostalgic atmosphere.',
          ),

          const Divider(height: 32),

          // Map
          sectionHeader('Map of Places'),
          SizedBox(
            height: 200,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(38.6031, 140.4068),
                zoom: 14,
              ),
              markers: <Marker>{
                Marker(
                  markerId: MarkerId('shirogane'),
                  position: LatLng(38.6031, 140.4068),
                  infoWindow: InfoWindow(title: 'Shirogane Falls'),
                ),
              },
            ),
          ),
        ],
      ),
    ),);
  }

  Widget sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
    );
  }

  Widget imageWithCaption(String path, String caption) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(path),
        ),
        const SizedBox(height: 4),
        Text(
          caption,
          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget infoCard({required String title, required String subtitle, String? trailing}) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.place),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing != null ? Text(trailing!) : null,
      ),
    );
  }

}
