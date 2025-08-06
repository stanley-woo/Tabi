// // File: lib/screens/detailed_itinerary_screen.dart

// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../models/itinerary.dart';
// import '../models/itinerary_block.dart';
// import '../services/itinerary_service.dart';

// /// Shows a single itinerary with collapsible cover, blocks, and actions.
// class DetailedItineraryScreen extends StatefulWidget {
//   final int id;
//   const DetailedItineraryScreen({Key? key, required this.id}) : super(key: key);

//   @override
//   State<DetailedItineraryScreen> createState() => _DetailedItineraryScreenState();
// }

// class _DetailedItineraryScreenState extends State<DetailedItineraryScreen> {
//   late Future<Itinerary> _futureItin;

//   @override
//   void initState() {
//     super.initState();
//     _futureItin = ItineraryService.fetchDetail(widget.id);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<Itinerary>(
//       future: _futureItin,
//       builder: (ctx, snap) {
//         if (snap.connectionState != ConnectionState.done) {
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         }
//         if (snap.hasError) {
//           return Scaffold(
//             body: Center(child: Text('Error: ${snap.error}')),
//           );
//         }
//         final itin = snap.data!;
//         // pick first image for header (if any)
//         final headerImage = itin.blocks.firstWhere(
//           (b) => b.type == 'image',
//           orElse: () => ItineraryBlock(id: 0, order: 0, type: 'image', content: ''),
//         ).content;

//         return Scaffold(
//           body: Stack(
//             children: [
//               NestedScrollView(
//                 headerSliverBuilder: (_, __) => [
//                   SliverAppBar(
//                     expandedHeight: 240,
//                     pinned: true,
//                     backgroundColor: Colors.white,
//                     elevation: 0,
//                     leading: IconButton(
//                       icon: const Icon(Icons.arrow_back, color: Colors.black),
//                       onPressed: () => Navigator.pop(context),
//                     ),
//                     flexibleSpace: FlexibleSpaceBar(
//                       titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
//                       title: Text(itin.title,
//                           style: GoogleFonts.poppins(
//                               color: Colors.black, fontWeight: FontWeight.w600)),
//                       background: Stack(
//                         fit: StackFit.expand,
//                         children: [
//                           if (headerImage.isNotEmpty)
//                             Image.network(headerImage, fit: BoxFit.cover)
//                           else
//                             Container(color: Colors.grey[200]),
//                           // light blur for frosted look
//                           Positioned.fill(
//                             child: BackdropFilter(
//                               filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
//                               child:
//                                   Container(color: Colors.white.withValues(alpha: 0)),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   )
//                 ],
//                 body: Container(
//                   color: Colors.white,
//                   child: ListView(
//                     padding: const EdgeInsets.all(16),
//                     children: [
//                       // Description
//                       Text(itin.description,
//                           style: GoogleFonts.poppins(
//                               fontSize: 16, color: Colors.black)),
//                       const SizedBox(height: 24),

//                       // Blocks
//                       ...itin.blocks.map((b) {
//                         if (b.type == 'text') {
//                           return Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 8),
//                             child: Text(b.content,
//                                 style: GoogleFonts.poppins(
//                                     fontSize: 14, color: Colors.black)),
//                           );
//                         } else if (b.type == 'image') {
//                           return Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 8),
//                             child: GestureDetector(
//                               // tap to zoom
//                               onTap: () => showDialog(
//                                   context: context,
//                                   builder: (_) => Dialog(
//                                         child: InteractiveViewer(
//                                           child: Image.network(b.content),
//                                         ),
//                                       )),
//                               child: ClipRRect(
//                                 borderRadius: BorderRadius.circular(12),
//                                 child: Image.network(b.content,
//                                     fit: BoxFit.cover),
//                               ),
//                             ),
//                           );
//                         }
//                         return const SizedBox.shrink();
//                       }).toList(),

//                       // bottom padding so content isn't hidden by buttons
//                       const SizedBox(height: 100),
//                     ],
//                   ),
//                 ),
//               ),

//               //  Glassy bottom bar with actions
//               Positioned(
//                 left: 16,
//                 right: 16,
//                 bottom: 24,
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(24),
//                   child: BackdropFilter(
//                     filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 16, vertical: 12),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.3),
//                         borderRadius: BorderRadius.circular(24),
//                         border:
//                             Border.all(color: Colors.white.withOpacity(0.2)),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           IconButton(
//                             icon: const Icon(Icons.favorite_border),
//                             color: Colors.redAccent,
//                             onPressed: () {
//                               // TODO: toggle favorite
//                             },
//                           ),
//                           ElevatedButton.icon(
//                             onPressed: () {
//                               // TODO: save/bookmark
//                             },
//                             icon: const Icon(Icons.bookmark_border),
//                             label: const Text('Save'),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.black,
//                               shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(32)),
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 24, vertical: 12),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }