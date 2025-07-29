// File: lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/itinerary.dart';
import '../models/itinerary_block.dart';
import '../services/itinerary_service.dart';

/// Home screen fetching "Explore" itineraries from the backend,
/// with search filtering and navigation into detail.
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<List<Itinerary>> _futureItineraries;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureItineraries = ItineraryService.fetchList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Explore Itineraries',
          style: GoogleFonts.poppins(
            color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          // SEARCH BAR (restyled)
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              style: GoogleFonts.poppins(),             // ← new
              decoration: InputDecoration(
                filled: true,                            // ← new
                fillColor: Colors.grey[200],             // ← new
                hintText: 'Search by location or tag…',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey[600],
                ),                                        // ← new
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,           // ← new
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // ITINERARY LIST
          Expanded(
            child: FutureBuilder<List<Itinerary>>(
              future: _futureItineraries,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text(
                    'Error: ${snapshot.error}',
                    style: GoogleFonts.poppins(color: Colors.red),
                  ));
                }

                final all = snapshot.data!;
                if (all.isEmpty) {
                  return Center(
                    child: Text(
                      'No trips found :(',
                      style: GoogleFonts.poppins(),
                    ),
                  );
                }

                final query = _searchCtrl.text.toLowerCase();
                final filtered = all.where((itin) {
                  return itin.title.toLowerCase().contains(query) ||
                      (itin.tags?.any((tag) =>
                              tag.toLowerCase().contains(query)) ??
                          false);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final itin = filtered[i];
                    final imgBlock = itin.blocks.firstWhere(
                      (b) => b.type == 'image',
                      orElse: () => ItineraryBlock(
                          id: 0,
                          order: 0,
                          type: 'image',
                          content:
                              'https://via.placeholder.com/400x200'),
                    );

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),      // ⬅ NEW
                        onTap: () => Navigator.pushNamed(
                            context, '/detail', arguments: itin.id),
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          clipBehavior: Clip.hardEdge,
                          elevation: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // COVER IMAGE
                              Image.network(
                                imgBlock.content,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 180,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(Icons.broken_image,
                                        size: 40, color: Colors.black26),
                                  ),
                                ),
                              ),

                              // TITLE
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  itin.title,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // BOTTOM NAVIGATION
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (i) {
          if (i == 1) {
            Navigator.pushNamed(context, '/create');
          } else if (i == 2) {
            Navigator.pushNamed(context, '/profile');
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: const Icon(Icons.add_circle), label: 'Create'),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person), label: 'You'),
        ],
      ),
    );
  }
}