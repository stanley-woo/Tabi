import 'package:flutter/material.dart';
import 'package:frontend/platform_map.dart';
import 'package:google_fonts/google_fonts.dart';

class DetailedItineraryDemo extends StatefulWidget {
  const DetailedItineraryDemo({super.key});

  @override
  State<DetailedItineraryDemo> createState() => _DetailedItineraryDemoState();
}

class _DetailedItineraryDemoState extends State<DetailedItineraryDemo> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};
  // late GoogleMapController _mapController;
  String? _mapStyle;

  final List<ItinerarySection> _sections = [
    ItinerarySection(
      id: 'morning',
      title: 'Morning: Shirogane Falls & Foot Bath',
      description:
          'Start your morning with a relaxing walk to Shirogane Falls, followed by a free foot bath nearby.',
      imagePath: 'assets/shirogane.jpg',
    ),
    ItinerarySection(
      id: 'afternoon',
      title: 'Afternoon: Cafe & Lunch',
      description:
          'Enjoy lunch at a retro cafe. Try homemade soba and Japanese sweets!',
      imagePath: 'assets/cafe.jpg',
    ),
    ItinerarySection(
      id: 'evening',
      title: 'Evening: Lantern-lit Walk',
      description:
          'Walk through gas-lit alleys and take in the nostalgic atmosphere.',
      imagePath: 'assets/lantern.jpg',
    ),
    ItinerarySection(
      id: 'map',
      title: 'Map of Places',
      description: '',
    ),
  ];

  @override
  void initState() {
    super.initState();

    for (var section in _sections) {
      _sectionKeys[section.id] = GlobalKey();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_mapStyle == null) {
      DefaultAssetBundle.of(context)
          .loadString('assets/map_style.json')
          .then((style) {
        setState(() {
          _mapStyle = style;
        });
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(String id) {
    final keyContext = _sectionKeys[id]?.currentContext;
    if (keyContext != null) {
      Scrollable.ensureVisible(
        keyContext,
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  // void _onMapCreated(GoogleMapController controller) {
  //   _mapController = controller;
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        title: Text(
          'Itinerary Detail',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            'A Day in Ginzan Onsen',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explore Scenic Hot Spring Streets, Charming Cafes With My Loved One',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2))
              ],
            ),
            child: ExpansionTile(
              title: Text(
                'Table of Contents',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: _sections
                  .map(
                    (section) => ListTile(
                      title: Text(
                        section.title,
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      onTap: () => _scrollToSection(section.id),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _sections.length,
              itemBuilder: (context, index) {
                final section = _sections[index];
                return Padding(
                  key: _sectionKeys[section.id],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: section.id == 'map'
                      ? _buildMapSection()
                      : _buildContentSection(section),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildContentSection(ItinerarySection section) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              section.imagePath,
              fit: BoxFit.cover,
              height: 200,
              width: double.infinity,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            section.description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Map of Places',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: PlatformMap(
            lat: 38.6031,
            lng: 140.4068,
            markerTitle: 'Hong Kong',
          ),
        )
      ],
    );
  }
}

class ItinerarySection {
  final String id;
  final String title;
  final String description;
  final String imagePath;

  ItinerarySection({
    required this.id,
    required this.title,
    required this.description,
    this.imagePath = '',
  });
}