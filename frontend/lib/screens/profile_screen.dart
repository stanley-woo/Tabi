import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/profile_service.dart';
import '../services/itinerary_service.dart';
import '../models/itinerary.dart';



class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color? backgroundColor;
  _SliverAppBarDelegate(this._tabBar, {this.backgroundColor});

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate old) =>
      old._tabBar != _tabBar || old.backgroundColor != backgroundColor;
}

/// Profile wired to backend. `username` = the profile being viewed,
/// `currentUser` = who is logged in (used for follow/save actions).
class ProfileScreen extends StatefulWidget {
  final String username;
  final String currentUser;
  const ProfileScreen({super.key, required this.username, required this.currentUser});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<Map<String, dynamic>> _futureProfile;
  late Future<List<Itinerary>> _futureCreated;
  late Future<List<Itinerary>> _futureSaved;
  late Future<bool> _futureIsFollowing;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    _futureProfile = ProfileService.fetchProfile(widget.username);
    _futureCreated = ItineraryService.fetchCreatedByUsername(widget.username);
    _futureSaved = ItineraryService.fetchSavedByUsername(widget.username);
    _futureIsFollowing = ProfileService.isFollowing(widget.currentUser, widget.username);
  }

  Future<void> _refresh() async {
    setState(_loadData);
    await Future.wait([_futureProfile, _futureCreated, _futureSaved]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: DefaultTabController(
          length: 2, 
          child: NestedScrollView(
            headerSliverBuilder: (_,_) => [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: const BackButton(color: Colors.white),
                flexibleSpace: FutureBuilder<Map<String, dynamic>>(
                  future: _futureProfile, 
                  builder: (ctx, snap) {
                    if(snap.connectionState != ConnectionState.done) {
                      return const Stack(
                        fit: StackFit.expand,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                colors: [Color(0x99000000), Color(0x19000000)],
                              ),
                            ),
                          ),
                          Center(child: CircularProgressIndicator()),
                        ],
                      );
                    }
                    if (snap.hasError || !snap.hasData) {
                      return Center(child: Text('Failed to load profile', style: GoogleFonts.poppins(color: Colors.white)));
                    }

                    // Unpack header payload
                    final p = snap.data!;
                    final uname = p['username'] as String? ?? widget.username;
                    final headerUrl = p['header_url'] as String?;
                    final avatarUrl = p['avatar_url'] as String?;
                    final bio = p['bio'] as String?;
                    final stats = p['stats'] as Map<String, dynamic>? ?? {};
                    final places = stats['places'] ?? 0;
                    final followers = stats['followers'] ?? 0;
                    final trips = stats['trips'] ?? 0;

                    return FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          if(headerUrl != null)
                            Image.network(headerUrl, fit: BoxFit.cover),
                          // gradient overlay for readability
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                colors: [Color(0x99000000), Color(0x19000000)]
                              ),
                            )
                          ),
                          if(avatarUrl != null)
                            Positioned(
                              bottom: 16, left: 16,
                              child: CircleAvatar(
                                radius: 48,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 44,
                                  backgroundImage: NetworkImage(avatarUrl)
                                ),
                              ),
                            ),
                          // stats row
                          Positioned(
                            bottom: 16, left: 128, right: 16,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _Stat(label: 'Places', value: '$places'),
                                _Stat(label: 'Followers', value: '$followers'),
                                _Stat(label: 'Trips', value: '$trips'),
                              ],
                            ),
                          ),
                          // username and bio
                          Positioned(
                            bottom: 16 + 48 + 8,
                            left: 128, right: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(uname, style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)),
                                if(bio != null && bio.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(bio, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12))
                                  ),
                              ],
                            ),
                          ),
                          // Follow button only if viewing someone else
                          if(widget.currentUser != widget.username)
                            Positioned(
                              top: 44,
                              right: 16,
                              child: FutureBuilder<bool>(
                                future: _futureIsFollowing,
                                builder: (ctx, s) {
                                  final isFollowing = s.data ?? false;
                                  return ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        if (isFollowing) {
                                          await ProfileService.unfollow(widget.currentUser, widget.username);
                                        } else {
                                          await ProfileService.follow(widget.currentUser, widget.username);
                                        }
                                        // refresh counts + following state
                                        await _refresh();
                                      } catch (_) {
                                        // optional: show SnackBar
                                      }
                                    },
                                    child: Text(isFollowing ? 'Following' : 'Follow'),
                                  );
                                },
                              ),
                            )
                        ],
                      ),
                    );
                  }),
              ),
              // Sticky tabs on the silver background
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorWeight: 3,
                    labelColor: Colors.black87,
                    unselectedLabelColor: Colors.black54,
                    labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    tabs: const [Tab(text: 'Created'), Tab(text: 'Saved')]
                  ),
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor
                ),
              ),
            ], 
            body: TabBarView(
              controller: _tabController,
              children: [
                FutureBuilder<List<Itinerary>>(
                  future: _futureCreated, 
                  builder: (ctx, snap) {
                    if(snap.connectionState != ConnectionState.done) {
                      return const Stack(
                        fit: StackFit.expand,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                colors: [Color(0x99000000), Color(0x19000000)],
                              ),
                            ),
                          ),
                          Center(child: CircularProgressIndicator()),
                        ],
                      );
                    }
                    if(snap.hasError) {
                      return Center(child: Text('Error: ${snap.error}', style: GoogleFonts.poppins()));
                    }
                    final list = snap.data ?? const <Itinerary>[];
                    if(list.isEmpty) {
                      return Center(child: Text('No trips yet', style: GoogleFonts.poppins()));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _ItinCard(
                        itin: list[i],
                        trailing: null
                      )
                    );
                  }
                ),

                // SAVED TAB
                FutureBuilder<List<Itinerary>>(
                  future: _futureSaved,
                  builder: (ctx, snap) {
                    if(snap.connectionState != ConnectionState.done) {
                      return const Stack(
                        fit: StackFit.expand,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                colors: [Color(0x99000000), Color(0x19000000)],
                              ),
                            ),
                          ),
                          Center(child: CircularProgressIndicator()),
                        ],
                      );
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Error: ${snap.error}', style: GoogleFonts.poppins()));
                    }
                    final list = snap.data ?? const <Itinerary>[];
                    if (list.isEmpty) {
                      return Center(child: Text('No saved trips yet', style: GoogleFonts.poppins()));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final itin = list[i];
                        return _ItinCard(
                          itin: itin,
                          trailing: IconButton(
                            tooltip: 'Unsave',
                            icon: const Icon(Icons.bookmark_remove),
                            onPressed: () async {
                              await ProfileService.unsaveTrip(widget.currentUser, itin.id);
                              setState(_loadData);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


/// Tiny stat pill used in the header
class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

/// Simple itinerary card (title-only for now; plug in image later)
class _ItinCard extends StatelessWidget {
  final Itinerary itin;
  final Widget? trailing;
  const _ItinCard({required this.itin, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(
          itin.title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        trailing: trailing,
        onTap: () {
          // Navigate to detail with your existing route (if wired)
          // Navigator.pushNamed(context, '/detail', arguments: itin.id);
        },
      ),
    );
  }
}
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       body: DefaultTabController(
//         length: 2,
//         child: NestedScrollView(
//           headerSliverBuilder: (_, _) => [
//             // 1) Only the cover/avatar/username/stats in the SliverAppBar:
//             SliverAppBar(
//               systemOverlayStyle: SystemUiOverlayStyle.light,
//               expandedHeight: 260,
//               pinned: true,
//               backgroundColor: Colors.transparent,
//               elevation: 0,
//               leading: const BackButton(color: Colors.white),
//               flexibleSpace: FlexibleSpaceBar(
//                 background: Stack(
//                   fit: StackFit.expand,
//                   children: [
//                     Image.network(_coverUrl, fit: BoxFit.cover),
//                     // gradient overlay
//                     DecoratedBox(
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           begin: Alignment.topCenter,
//                           end: Alignment.bottomCenter,
//                           colors: [
//                             Colors.black.withAlpha(153),
//                             Colors.black.withAlpha(25),
//                           ],
//                         ),
//                       ),
//                     ),
//                     // avatar
//                     Positioned(
//                       bottom: 16, left: 16,
//                       child: CircleAvatar(
//                         radius: 48,
//                         backgroundColor: Colors.white,
//                         child: CircleAvatar(
//                           radius: 44,
//                           backgroundImage: NetworkImage(_avatarUrl),
//                         ),
//                       ),
//                     ),
//                     // stats row
//                     Positioned(
//                       bottom: 16, left: 128, right: 16,
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           _Stat(label: 'Places',    value: '69'),
//                           _Stat(label: 'Followers', value: '643k'),
//                           _Stat(label: 'Trips',     value: '262'),
//                         ],
//                       ),
//                     ),
//                     // username above stats (optional if you want it here)
//                     Positioned(
//                       bottom: 16 + 48 + 8, // avatar radius + small gap
//                       left: 128,
//                       child: Text(
//                         '@$_username',
//                         style: GoogleFonts.poppins(
//                           color: Colors.white,
//                           fontSize: 24,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             // 2) Your sticky TabBar in its own sliver:
//             SliverPersistentHeader(
//               pinned: true,
//               delegate: _SliverAppBarDelegate(
//                 TabBar(
//                   controller: _tabController,
//                   indicatorColor: Colors.black,
//                   indicatorWeight: 3,
//                   labelColor: Colors.black,
//                   unselectedLabelColor: Colors.black,
//                   labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
//                   tabs: const [
//                     Tab(text: 'Created'),
//                     Tab(text: 'Saved'),
//                   ],
//                 ),
//               ),
//             ),
//           ],

//           // 3) The TabBarView below…
//           body: TabBarView(
//             controller: _tabController,
//             children: [
//               _buildCreatedTab(),
//               _buildSavedTab(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }


//   Widget _buildCreatedTab() {
//     return FutureBuilder<List<Itinerary>>(
//       future: _futureCreated,
//       builder: (ctx, snap) {
//         if (snap.connectionState != ConnectionState.done) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         if (snap.hasError) {
//           return Center(child: Text('Error: ${snap.error}', style: GoogleFonts.poppins()));
//         }
//         final list = snap.data ?? [];
//         if (list.isEmpty) {
//           return Center(child: Text('No trips here yet', style: GoogleFonts.poppins(fontSize: 16)));
//         }
//         return ListView.builder(
//           padding: const EdgeInsets.all(12),
//           itemCount: list.length,
//           itemBuilder: (c, i) => _buildItinCard(list[i]),
//         );
//       },
//     );
//   }

// Widget _buildSavedTab() {
//   // placeholder for now
//   return Center(child: Text('No saved trips yet', style: GoogleFonts.poppins(fontSize: 16)));
// }

//   Widget _buildItinCard(Itinerary itin) {
//     // 1. Flatten all blocks across days:
//     final allBlocks = itin.days.expand((d) => d.blocks);

//     // 2. Find image block if any:
//     ItineraryBlock? imageBlock;
//     if (allBlocks.where((b) => b.type == 'image').isNotEmpty) {
//       imageBlock = allBlocks.firstWhere((b) => b.type == 'image');
//     }

//     final imgUrl = imageBlock?.content;

//     return GestureDetector(
//       onTap: () => Navigator.pushNamed(context, '/detail', arguments: itin.id),
//       child: Card(
//         // …
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (imgUrl != null)
//               Image.network(
//                 imgUrl,
//                 height: 160,
//                 width: double.infinity,
//                 fit: BoxFit.cover,
//               ),
//             Padding(
//               padding: const EdgeInsets.all(12),
//               child: Text(
//                 itin.title,
//                 style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

// class _Stat extends StatelessWidget {
//   final String label, value;
//   const _Stat({required this.label, required this.value});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Text(value, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
//         const SizedBox(height: 4),
//         Text(label, style: TextStyle(color: Colors.white70, fontSize: 12))
//       ],
//     );
//   }
// }