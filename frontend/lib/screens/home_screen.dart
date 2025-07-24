// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../models/itinerary.dart';
// import '../models/itinerary_block.dart';
// import '../services/itinerary_service.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({Key? key}) : super(key: key);
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   late Future<List<Itinerary>> _futureItins;
//   final _searchCtrl = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _futureItins = ItineraryService.fetchList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       bottomNavigationBar: BottomNavigationBar(
//         backgroundColor: Colors.white,
//         selectedItemColor: Theme.of(context).colorScheme.primary,
//         unselectedItemColor: Colors.grey,
//         currentIndex: 0,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//           BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Create'),
//           BottomNavigationBarItem(icon: Icon(Icons.person), label: 'You'),
//         ],
//         onTap: (i) {
//           if (i == 1) Navigator.pushNamed(context, '/create');
//           if (i == 2) Navigator.pushNamed(context, '/profile');
//         },
//       ),
//       body: NestedScrollView(
//         headerSliverBuilder: (_, __) => [
//           SliverAppBar(
//             backgroundColor: Colors.transparent,
//             expandedHeight: 200,
//             pinned: true,
//             flexibleSpace: FlexibleSpaceBar(
//               title: Text(
//                 'Explore',
//                 style: GoogleFonts.poppins(color: Colors.white, fontSize: 20),
//               ),
//               background: Container(color: Theme.of(context).colorScheme.primary),
//               titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
//             ),
//           ),
//         ],
//         body: Container(
//           margin: const EdgeInsets.only(top: 16),
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//           ),
//           child: Column(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(12),
//                 child: TextField(
//                   controller: _searchCtrl,
//                   decoration: InputDecoration(
//                     filled: true,
//                     fillColor: Colors.grey[200],
//                     hintText: 'Search by location or tag…',
//                     prefixIcon: const Icon(Icons.search),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(30),
//                       borderSide: BorderSide.none,
//                     ),
//                     contentPadding:
//                         const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
//                   ),
//                   onChanged: (_) => setState(() {}),
//                 ),
//               ),
//               Expanded(
//                 child: FutureBuilder<List<Itinerary>>(
//                   future: _futureItins,
//                   builder: (ctx, snap) {
//                     if (snap.connectionState != ConnectionState.done)
//                       return const Center(child: CircularProgressIndicator());
//                     if (snap.hasError)
//                       return Center(child: Text('Error: ${snap.error}'));
//                     final all = snap.data!;
//                     final filtered = all.where((it) {
//                       final q = _searchCtrl.text.toLowerCase();
//                       return it.title.toLowerCase().contains(q) ||
//                           it.tags
//                                   ?.any((t) => t.toLowerCase().contains(q)) ==
//                               true;
//                     }).toList();

//                     return ListView.builder(
//                       padding: const EdgeInsets.symmetric(vertical: 6),
//                       itemCount: filtered.length,
//                       itemBuilder: (c, i) {
//                         final itin = filtered[i];
//                         final imgBlock = itin.blocks.firstWhere(
//                             (b) => b.type == 'image',
//                             orElse: () => ItineraryBlock(
//                                   id: 0,
//                                   order: 0,
//                                   type: 'image',
//                                   content:
//                                       'https://via.placeholder.com/400x200',
//                                 ));
//                         return Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 12),
//                           child: InkWell(
//                             borderRadius: BorderRadius.circular(12),
//                             onTap: () => Navigator.pushNamed(
//                                 context, '/detail',
//                                 arguments: itin.id),
//                             child: Card(
//                               clipBehavior: Clip.hardEdge,
//                               shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(12)),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Image.network(
//                                     imgBlock.content,
//                                     height: 180,
//                                     width: double.infinity,
//                                     fit: BoxFit.cover,
//                                   ),
//                                   Padding(
//                                     padding: const EdgeInsets.all(12),
//                                     child: Text(itin.title,
//                                         style: GoogleFonts.poppins(
//                                             fontSize: 16,
//                                             fontWeight: FontWeight.bold)),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
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
    // Fetch the explore feed on startup
    _futureItineraries = ItineraryService.fetchList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore Itineraries')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search by location or tag…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Itinerary>>(
              future: _futureItineraries,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                // Filter by search query
                final all = snapshot.data!;
                if (all.isEmpty) {
                  return const Center(child: Text('No trips found :('));
                }
                final query = _searchCtrl.text.toLowerCase();
                final filtered = all.where((itin) {
                  return itin.title.toLowerCase().contains(query) ||
                      itin.tags?.any(
                              (tag) => tag.toLowerCase().contains(query)) ==
                          true;
                }).toList();

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final itin = filtered[i];
                    // Find first image block for card cover
                    final imgBlock = itin.blocks
                        .firstWhere((b) => b.type == 'image', orElse: () =>
                            ItineraryBlock(
                                id: 0,
                                order: 0,
                                type: 'image',
                                content:
                                    'https://via.placeholder.com/400x200'));

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.pushNamed(
                            context, '/detail', arguments: itin.id),
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          clipBehavior: Clip.hardEdge,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Display the cover image
                              Image.network(
                                imgBlock.content,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 180,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(Icons.broken_image, size: 40, color: Colors.black26),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(itin.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
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
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'You'),
        ],
        currentIndex: 0,
        onTap: (i) {
          if (i == 1) {
            Navigator.pushNamed(context, '/create');
          } else if (i == 2) {
            Navigator.pushNamed(context, '/profile');
          }
        },
      ),
    );
  }
}