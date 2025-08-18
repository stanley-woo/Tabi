import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state/auth_store.dart';
import '../models/itinerary.dart';
import '../models/itinerary_block.dart';
import '../services/itinerary_service.dart';
import 'home_search_sheet.dart';
import 'package:frontend/navigation/profile_args.dart' as nav;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<List<Itinerary>> _futureItineraries;

  // single source of truth for search filter
  String? _query;

  @override
  void initState() {
    super.initState();
    _futureItineraries = ItineraryService.fetchList();
  }

  /// Open the unified search sheet and store the returned query.
  Future<void> _openSearch() async {
    // read once (don’t rebuild on change)
    final me = context.read<AuthStore>().username ?? 'julieee_mun';

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.9,
        builder: (_, __) => HomeSearchSheet(
          currentUser: me,
          initialQuery: _query,
        ),
      ),
    );

    if (result != null) {
      setState(() => _query = result.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    // watch so UI updates if the logged-in user changes
    final me = context.watch<AuthStore>().username ?? 'julieee_mun';
    final q = (_query ?? '').toLowerCase();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Explore Itineraries',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          // Search pill
          Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: _openSearch,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.black54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        q.isEmpty ? 'Search trips or people' : _query!,
                        style: GoogleFonts.poppins(color: Colors.black54),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (q.isNotEmpty)
                      IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close,
                            size: 18, color: Colors.black45),
                        onPressed: () => setState(() => _query = ''),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Itinerary list
          Expanded(
            child: FutureBuilder<List<Itinerary>>(
              future: _futureItineraries,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: GoogleFonts.poppins(color: Colors.red),
                    ),
                  );
                }

                final all = snapshot.data ?? const <Itinerary>[];
                final filtered = q.isEmpty
                    ? all
                    : all.where((itin) {
                        final inTitle =
                            itin.title.toLowerCase().contains(q);
                        final inTags = (itin.tags?.any(
                              (t) => t.toLowerCase().contains(q),
                            ) ??
                            false);
                        return inTitle || inTags;
                      }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child:
                        Text('No trips found', style: GoogleFonts.poppins()),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final itin = filtered[i];

                    // first image block across days (fallback placeholder)
                    final imgBlock = itin.days
                        .expand((d) => d.blocks)
                        .firstWhere(
                          (b) => b.type == 'image',
                          orElse: () => ItineraryBlock(
                            id: 0,
                            dayGroupId: 0,
                            order: 0,
                            type: 'image',
                            content: 'https://via.placeholder.com/800x400',
                          ),
                        );

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/detail',
                          arguments: itin.id,
                        ),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.hardEdge,
                          elevation: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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

      // Bottom nav
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (i) {
          if (i == 1) {
            Navigator.pushNamed(context, '/create');
          } else if (i == 2) {
            Navigator.pushNamed(
              context,
              '/profile',
              arguments: nav.ProfileArgs(me, me), // <-- use logged-in user
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'You'),
        ],
      ),
    );
  }
}