import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/itinerary.dart';
import '../services/profile_service.dart';

/// Displays a user profile with a collapsible cover header, avatar,
/// and tabs for Created & Saved itineraries.
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
    final accent = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              leading: const BackButton(color: Colors.black),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, bottom: 48),
                title: Text(
                  '@$_username',
                  style: GoogleFonts.poppins(
                      color: Colors.black, fontWeight: FontWeight.w600),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(_coverUrl, fit: BoxFit.cover),
                    // dark gradient for readability
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black45, Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    // avatar
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 44,
                          backgroundImage: NetworkImage(_avatarUrl),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: accent,
                indicatorWeight: 3,
                labelColor: Colors.black,
                labelStyle:
                    GoogleFonts.poppins(fontWeight: FontWeight.w600),
                unselectedLabelColor: Colors.grey[600],
                tabs: const [
                  Tab(text: 'Created'),
                  Tab(text: 'Saved'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              // CREATED TAB
              FutureBuilder<List<Itinerary>>(
                future: _futureCreated,
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                        child: Text('Error: ${snap.error}',
                            style: GoogleFonts.poppins()));
                  }
                  final list = snap.data!;
                  if (list.isEmpty) {
                    return Center(
                      child: Text('No trips here yet',
                          style: GoogleFonts.poppins(fontSize: 16)),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: list.length,
                    itemBuilder: (c, i) => _buildItinCard(list[i]),
                  );
                },
              ),

              // SAVED TAB (placeholder)
              Center(
                child: Text('No saved trips yet',
                    style: GoogleFonts.poppins(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItinCard(Itinerary itin) {
    final hasImage = itin.blocks.any((b) => b.type == 'image');
    final imgUrl = hasImage
        ? itin.blocks.firstWhere((b) => b.type == 'image').content
        : null;

    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/detail', arguments: itin.id),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.hardEdge,
        elevation: 2,
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
              child: Text(itin.title,
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}