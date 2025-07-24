// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../models/itinerary.dart';
// import '../models/itinerary_block.dart';

// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({Key? key}) : super(key: key);
//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabCtlr;
//   final String _username = 'Sarah';
//   final String _avatarUrl = 'https://i.pravatar.cc/150?img=5';

//   // replace these with real fetched lists later
//   final List<Itinerary> _created = [];
//   final List<Itinerary> _saved = [];

//   @override
//   void initState() {
//     super.initState();
//     _tabCtlr = TabController(length: 2, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabCtlr.dispose();
//     super.dispose();
//   }

//   Widget _listView(List<Itinerary> list) {
//     if (list.isEmpty) {
//       return Center(child: Text('No trips here yet', style: GoogleFonts.poppins()));
//     }

//     return ListView.builder(
//       padding: const EdgeInsets.all(12),
//       itemCount: list.length,
//       itemBuilder: (_, i) {
//         final it = list[i];
//         // ❗️ extract first image block, fallback to placeholder
//         final imgBlock = it.blocks.firstWhere(
//           (b) => b.type == 'image',
//           orElse: () => ItineraryBlock(
//             id: 0,
//             order: 0,
//             type: 'image',
//             content: 'https://via.placeholder.com/400x200',
//           ),
//         );

//         return GestureDetector(
//           onTap: () => Navigator.pushNamed(context, '/detail', arguments: it.id),
//           child: Card(
//             clipBehavior: Clip.hardEdge,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             margin: const EdgeInsets.symmetric(vertical: 8),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Image.network(
//                   imgBlock.content,
//                   height: 160,
//                   width: double.infinity,
//                   fit: BoxFit.cover,
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(12),
//                   child: Text(it.title,
//                       style: GoogleFonts.poppins(
//                           fontSize: 16, fontWeight: FontWeight.w600)),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       bottomNavigationBar: BottomNavigationBar(
//         backgroundColor: Colors.white,
//         selectedItemColor: Theme.of(context).colorScheme.primary,
//         unselectedItemColor: Colors.grey,
//         currentIndex: 2,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//           BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Create'),
//           BottomNavigationBarItem(icon: Icon(Icons.person), label: 'You'),
//         ],
//         onTap: (i) {
//           if (i == 0) Navigator.pushNamed(context, '/home');
//           if (i == 1) Navigator.pushNamed(context, '/create');
//         },
//       ),
//       body: NestedScrollView(
//         headerSliverBuilder: (_, __) => [
//           SliverAppBar(
//             backgroundColor: Colors.transparent,
//             expandedHeight: 240,
//             pinned: true,
//             flexibleSpace: FlexibleSpaceBar(
//               titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
//               title: Text('@$_username',
//                   style: GoogleFonts.poppins(color: Colors.white)),
//               background:
//                   Container(color: Theme.of(context).colorScheme.primary),
//             ),
//             leading: IconButton(
//               icon: const Icon(Icons.arrow_back, color: Colors.white),
//               onPressed: () => Navigator.pop(context),
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
//               const SizedBox(height: 16),
//               CircleAvatar(
//                 radius: 48,
//                 backgroundImage: NetworkImage(_avatarUrl),
//               ),
//               const SizedBox(height: 8),
//               Text('Travel Enthusiast',
//                   style: GoogleFonts.poppins(color: Colors.grey[600])),
//               const SizedBox(height: 24),
//               TabBar(
//                 controller: _tabCtlr,
//                 labelColor: Colors.black,
//                 unselectedLabelColor: Colors.grey,
//                 indicatorColor: Theme.of(context).colorScheme.primary,
//                 tabs: const [
//                   Tab(text: 'Created / Forked'),
//                   Tab(text: 'Saved'),
//                 ],
//               ),
//               Expanded(
//                 child: TabBarView(
//                   controller: _tabCtlr,
//                   children: [
//                     _listView(_created),
//                     _listView(_saved),
//                   ],
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
import 'package:google_fonts/google_fonts.dart';
import '../models/itinerary.dart';
import '../services/profile_service.dart';

/// Displays a user profile with tabs for Created and Saved itineraries,
/// loading Created itineraries from the backend.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final Future<List<Itinerary>> _futureCreated;

  final String _username = 'Sarah';
  final String _avatarUrl = 'https://i.pravatar.cc/150?img=5';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Kick off the fetch of the user's created itineraries
    _futureCreated = ProfileService.fetchUserItineraries(_username);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('@$_username', style: GoogleFonts.poppins()),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.secondary,
          tabs: const [Tab(text: 'Created'), Tab(text: 'Saved')],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 48,
            backgroundImage: NetworkImage(_avatarUrl),
          ),
          const SizedBox(height: 8),
          Text('Travel Enthusiast',
              style: GoogleFonts.poppins(color: Colors.grey[600])),
          const SizedBox(height: 24),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Created tab: show data from backend
                FutureBuilder<List<Itinerary>>(
                  future: _futureCreated,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: \${snapshot.error}'));
                    }
                    final createdList = snapshot.data!;
                    return _itineraryListView(createdList);
                  },
                ),
                // Saved tab: currently no backend, show placeholder
                Center(
                  child: Text('No saved trips yet',
                      style: GoogleFonts.poppins()),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _itineraryListView(List<Itinerary> list) {
    if (list.isEmpty) {
      return Center(
        child: Text('No trips here yet', style: GoogleFonts.poppins()),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final itin = list[i];
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/detail',
              arguments: itin.id),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Use first image block if available
                if (itin.blocks.any((b) => b.type == 'image'))
                  Image.network(
                    itin.blocks
                        .firstWhere((b) => b.type == 'image')
                        .content,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(itin.title,
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}