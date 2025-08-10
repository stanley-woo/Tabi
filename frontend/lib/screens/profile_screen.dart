import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/itinerary.dart';
import '../models/itinerary_block.dart';
import '../services/profile_service.dart';
import 'package:flutter/services.dart';

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
    // Use the app's scaffold bg (your silver) behind the tabs
    return Container(
      color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate old) =>
      old._tabBar != _tabBar || old.backgroundColor != backgroundColor;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final Future<List<Itinerary>> _futureCreated;

  final String _username = 'Sarah';
  final String _avatarUrl = 'https://i.pravatar.cc/150?img=5';
  final String _coverUrl =
      'https://picsum.photos/800/400?gravity=center';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      backgroundColor: Colors.grey[100],
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (_, _) => [
            // 1) Only the cover/avatar/username/stats in the SliverAppBar:
            SliverAppBar(
              systemOverlayStyle: SystemUiOverlayStyle.light,
              expandedHeight: 260,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: const BackButton(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(_coverUrl, fit: BoxFit.cover),
                    // gradient overlay
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withAlpha(153),
                            Colors.black.withAlpha(25),
                          ],
                        ),
                      ),
                    ),
                    // avatar
                    Positioned(
                      bottom: 16, left: 16,
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 44,
                          backgroundImage: NetworkImage(_avatarUrl),
                        ),
                      ),
                    ),
                    // stats row
                    Positioned(
                      bottom: 16, left: 128, right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _Stat(label: 'Places',    value: '69'),
                          _Stat(label: 'Followers', value: '643k'),
                          _Stat(label: 'Trips',     value: '262'),
                        ],
                      ),
                    ),
                    // username above stats (optional if you want it here)
                    Positioned(
                      bottom: 16 + 48 + 8, // avatar radius + small gap
                      left: 128,
                      child: Text(
                        '@$_username',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2) Your sticky TabBar in its own sliver:
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.black,
                  indicatorWeight: 3,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.black,
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Created'),
                    Tab(text: 'Saved'),
                  ],
                ),
              ),
            ),
          ],

          // 3) The TabBarView below…
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildCreatedTab(),
              _buildSavedTab(),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildCreatedTab() {
    return FutureBuilder<List<Itinerary>>(
      future: _futureCreated,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}', style: GoogleFonts.poppins()));
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return Center(child: Text('No trips here yet', style: GoogleFonts.poppins(fontSize: 16)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (c, i) => _buildItinCard(list[i]),
        );
      },
    );
  }

Widget _buildSavedTab() {
  // placeholder for now
  return Center(child: Text('No saved trips yet', style: GoogleFonts.poppins(fontSize: 16)));
}

  Widget _buildItinCard(Itinerary itin) {
    // 1. Flatten all blocks across days:
    final allBlocks = itin.days.expand((d) => d.blocks);

    // 2. Find image block if any:
    ItineraryBlock? imageBlock;
    if (allBlocks.where((b) => b.type == 'image').isNotEmpty) {
      imageBlock = allBlocks.firstWhere((b) => b.type == 'image');
    }

    final imgUrl = imageBlock?.content;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/detail', arguments: itin.id),
      child: Card(
        // …
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imgUrl != null)
              Image.network(
                imgUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                itin.title,
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12))
      ],
    );
  }
}