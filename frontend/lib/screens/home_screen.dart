import 'package:flutter/material.dart';
import 'package:frontend/widgets/image_ref.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state/auth_store.dart';
import '../models/itinerary.dart';
import '../models/itinerary_block.dart';
import '../services/itinerary_service.dart';
import '../services/profile_service.dart';
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
    final me = context.read<AuthStore>().username ?? '';

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
        builder: (_, _) => HomeSearchSheet(
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
    final me = context.watch<AuthStore>().username ?? '';
    final q = (_query ?? '').toLowerCase();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0, // rely on shape for the hairline
          shape: const Border(
            bottom: BorderSide(color: Color(0x14000000), width: 1),
          ),
          toolbarHeight: 0, // hide normal title row
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kTextTabBarHeight), // 48
            child: SizedBox(
              height: kTextTabBarHeight, // if you still see 1px overflow, make this 50
              child: Row(
                children: [
                  Expanded(
                    child: TabBar(
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.black45,
                      indicatorColor: Colors.teal,
                      tabs: const [
                        Tab(text: 'Explore'),
                        Tab(text: 'Following'),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Search',
                    icon: const Icon(Icons.search, color: Colors.black87),
                    onPressed: _openSearch,
                  ),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _explorePane(q),        // uses your existing list logic
            _followingPane(q, me),  // following feed
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
                arguments: nav.ProfileArgs(me, me), // logged-in user
              );
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Create'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'You'),
          ],
        ),
      ),
    );
  }
  
  Widget _explorePane(String q) {
    // reuse your existing fetch-all future
    return _feedList(_futureItineraries, q);
  }

  Widget _followingPane(String q, String me) {
    final future = Future.wait([
      _futureItineraries,                         // List<Itinerary>
      ProfileService.fetchFollowingIds(me).catchError((e) {
        return <int>[]; // Return empty list on error
      }),       // List<int>
    ]).then<List<Itinerary>>((res) {
      final all = res[0] as List<Itinerary>;
      final followingIds = Set<int>.from(res[1] as List<int>);
      return all.where((i) => followingIds.contains(i.creatorId)).toList();
    });

    return _feedList(future, q);
  }

    Widget _feedList(Future<List<Itinerary>> future, String q) {
    return FutureBuilder<List<Itinerary>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: GoogleFonts.poppins(color: Colors.red)),
          );
        }

        final all = snapshot.data ?? const <Itinerary>[];
        final filtered = q.isEmpty
            ? all
            : all.where((itin) {
                final inTitle = itin.title.toLowerCase().contains(q);
                final inTags = (itin.tags?.any((t) => t.toLowerCase().contains(q)) ?? false);
                return inTitle || inTags;
              }).toList();

        if (filtered.isEmpty) {
          return Center(child: Text('No trips found', style: GoogleFonts.poppins()));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) {
            final itin = filtered[i];
            final imgBlock = itin.days
                .expand((d) => d.blocks)
                .firstWhere(
                  (b) => b.type == 'image',
                  orElse: () => ItineraryBlock(
                    id: 0, dayGroupId: 0, order: 0, type: 'image',
                    content: 'https://via.placeholder.com/800x400',
                  ),
                );

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.pushNamed(context, '/detail', arguments: itin.id),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  clipBehavior: Clip.hardEdge,
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      imageFromRef(imgBlock.content, height: 180, width: double.infinity, fit: BoxFit.cover),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          itin.title,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
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
    );
  }
}