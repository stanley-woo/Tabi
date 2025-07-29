// File: lib/screens/detailed_itinerary_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/itinerary.dart';
import '../models/itinerary_block.dart';
import '../services/itinerary_service.dart';

/// Shows a single itinerary with collapsible cover, blocks, and actions.
class DetailedItineraryScreen extends StatefulWidget {
  final int id;
  const DetailedItineraryScreen({Key? key, required this.id}) : super(key: key);

  @override
  State<DetailedItineraryScreen> createState() => _DetailedItineraryScreenState();
}

class _DetailedItineraryScreenState extends State<DetailedItineraryScreen> {
  late Future<Itinerary> _futureItin;

  @override
  void initState() {
    super.initState();
    _futureItin = ItineraryService.fetchDetail(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Itinerary>(
      future: _futureItin,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snap.error}')),
          );
        }
        final itin = snap.data!;
        // pick first image for header (if any)
        final headerImage = itin.blocks.firstWhere(
          (b) => b.type == 'image',
          orElse: () => ItineraryBlock(id: 0, order: 0, type: 'image', content: ''),
        ).content;

        return Scaffold(
          body: Stack(
            children: [
              NestedScrollView(
                headerSliverBuilder: (_, __) => [
                  SliverAppBar(
                    expandedHeight: 240,
                    pinned: true,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                      title: Text(itin.title,
                          style: GoogleFonts.poppins(
                              color: Colors.black, fontWeight: FontWeight.w600)),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (headerImage.isNotEmpty)
                            Image.network(headerImage, fit: BoxFit.cover)
                          else
                            Container(color: Colors.grey[200]),
                          // light blur for frosted look
                          Positioned.fill(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                              child:
                                  Container(color: Colors.white.withValues(alpha: 0)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
                body: Container(
                  color: Colors.white,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Description
                      Text(itin.description,
                          style: GoogleFonts.poppins(
                              fontSize: 16, color: Colors.black)),
                      const SizedBox(height: 24),

                      // Blocks
                      ...itin.blocks.map((b) {
                        if (b.type == 'text') {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(b.content,
                                style: GoogleFonts.poppins(
                                    fontSize: 14, color: Colors.black)),
                          );
                        } else if (b.type == 'image') {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: GestureDetector(
                              // tap to zoom
                              onTap: () => showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                        child: InteractiveViewer(
                                          child: Image.network(b.content),
                                        ),
                                      )),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(b.content,
                                    fit: BoxFit.cover),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }).toList(),

                      // bottom padding so content isn't hidden by buttons
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              //  Glassy bottom bar with actions
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(24),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.favorite_border),
                            color: Colors.redAccent,
                            onPressed: () {
                              // TODO: toggle favorite
                            },
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: save/bookmark
                            },
                            icon: const Icon(Icons.bookmark_border),
                            label: const Text('Save'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:frontend/platform_map.dart';
// import 'package:google_fonts/google_fonts.dart';

// class DetailedItineraryDemo extends StatefulWidget {
//   const DetailedItineraryDemo({super.key});

//   @override
//   State<DetailedItineraryDemo> createState() => _DetailedItineraryDemoState();
// }

// class _DetailedItineraryDemoState extends State<DetailedItineraryDemo> {
//   final ScrollController _scrollController = ScrollController();
//   final Map<String, GlobalKey> _sectionKeys = {};
//   // late GoogleMapController _mapController;
//   String? _mapStyle;

//   final List<ItinerarySection> _sections = [
//     ItinerarySection(
//       id: 'morning',
//       title: 'Morning: Shirogane Falls & Foot Bath',
//       description:
//           'Start your morning with a relaxing walk to Shirogane Falls, followed by a free foot bath nearby.',
//       imagePath: 'assets/shirogane.jpg',
//     ),
//     ItinerarySection(
//       id: 'afternoon',
//       title: 'Afternoon: Cafe & Lunch',
//       description:
//           'Enjoy lunch at a retro cafe. Try homemade soba and Japanese sweets!',
//       imagePath: 'assets/cafe.jpg',
//     ),
//     ItinerarySection(
//       id: 'evening',
//       title: 'Evening: Lantern-lit Walk',
//       description:
//           'Walk through gas-lit alleys and take in the nostalgic atmosphere.',
//       imagePath: 'assets/lantern.jpg',
//     ),
//     ItinerarySection(
//       id: 'map',
//       title: 'Map of Places',
//       description: '',
//     ),
//   ];

//   @override
//   void initState() {
//     super.initState();

//     for (var section in _sections) {
//       _sectionKeys[section.id] = GlobalKey();
//     }
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();

//     if (_mapStyle == null) {
//       DefaultAssetBundle.of(context)
//           .loadString('assets/map_style.json')
//           .then((style) {
//         setState(() {
//           _mapStyle = style;
//         });
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }

//   void _scrollToSection(String id) {
//     final keyContext = _sectionKeys[id]?.currentContext;
//     if (keyContext != null) {
//       Scrollable.ensureVisible(
//         keyContext,
//         duration: const Duration(milliseconds: 600),
//         curve: Curves.fastOutSlowIn,
//       );
//     }
//   }

//   // void _onMapCreated(GoogleMapController controller) {
//   //   _mapController = controller;
//   // }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F7),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 0.5,
//         title: Text(
//           'Itinerary Detail',
//           style: GoogleFonts.poppins(
//             fontWeight: FontWeight.bold,
//             color: Colors.black,
//           ),
//         ),
//       ),
//       body: Column(
//         children: [
//           const SizedBox(height: 12),
//           Text(
//             'A Day in Ginzan Onsen',
//             style: GoogleFonts.poppins(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Explore Scenic Hot Spring Streets, Charming Cafes With My Loved One',
//             textAlign: TextAlign.center,
//             style: GoogleFonts.poppins(
//               fontSize: 16,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 16),

//           Container(
//             margin: const EdgeInsets.symmetric(horizontal: 16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                     color: Colors.black12,
//                     blurRadius: 4,
//                     offset: Offset(0, 2))
//               ],
//             ),
//             child: ExpansionTile(
//               title: Text(
//                 'Table of Contents',
//                 style: GoogleFonts.poppins(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               children: _sections
//                   .map(
//                     (section) => ListTile(
//                       title: Text(
//                         section.title,
//                         style: GoogleFonts.poppins(fontSize: 14),
//                       ),
//                       onTap: () => _scrollToSection(section.id),
//                     ),
//                   )
//                   .toList(),
//             ),
//           ),

//           const SizedBox(height: 8),

//           Expanded(
//             child: ListView.builder(
//               controller: _scrollController,
//               itemCount: _sections.length,
//               itemBuilder: (context, index) {
//                 final section = _sections[index];
//                 return Padding(
//                   key: _sectionKeys[section.id],
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   child: section.id == 'map'
//                       ? _buildMapSection()
//                       : _buildContentSection(section),
//                 );
//               },
//             ),
//           )
//         ],
//       ),
//     );
//   }

//   Widget _buildContentSection(ItinerarySection section) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: 6,
//             offset: Offset(0, 3),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             section.title,
//             style: GoogleFonts.poppins(
//               fontSize: 20,
//               fontWeight: FontWeight.w600,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 12),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(12),
//             child: Image.asset(
//               section.imagePath,
//               fit: BoxFit.cover,
//               height: 200,
//               width: double.infinity,
//             ),
//           ),
//           const SizedBox(height: 12),
//           Text(
//             section.description,
//             style: GoogleFonts.poppins(
//               fontSize: 14,
//               color: Colors.grey[700],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMapSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Map of Places',
//           style: GoogleFonts.poppins(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Colors.redAccent,
//           ),
//         ),
//         const SizedBox(height: 8),
//         SizedBox(
//           height: 200,
//           child: PlatformMap(
//             lat: 38.6031,
//             lng: 140.4068,
//             markerTitle: 'Hong Kong',
//           ),
//         )
//       ],
//     );
//   }
// }

// class ItinerarySection {
//   final String id;
//   final String title;
//   final String description;
//   final String imagePath;

//   ItinerarySection({
//     required this.id,
//     required this.title,
//     required this.description,
//     this.imagePath = '',
//   });
// }