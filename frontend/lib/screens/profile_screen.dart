import 'package:flutter/material.dart';
import 'package:frontend/widgets/image_ref.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/profile_service.dart';
import '../services/itinerary_service.dart';
import '../models/itinerary.dart';
import 'package:provider/provider.dart';
import '../state/auth_store.dart';

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
  const ProfileScreen({
    super.key,
    required this.username,
    required this.currentUser,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  late Future<Map<String, dynamic>> _futureProfile;
  late Future<List<Itinerary>> _futureCreated;
  late Future<List<Itinerary>> _futureSaved;

  // Follow-state UI
  bool? _isFollowing; // null while loading
  int? _followerCount; // show immediately & keep in sync with toggle

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initFollowState();
  }

  void _initFollowState() {
    final me = context.read<AuthStore?>()?.username ?? widget.currentUser;
    if (me == widget.username) {
      if (_isFollowing != null) setState(() => _isFollowing = null);
      return;
    }
    ProfileService.isFollowing(me, widget.username).then((isF) {
      if (mounted) setState(() => _isFollowing = isF);
    }).catchError((_) {
      if (mounted) setState(() => _isFollowing = false);
    });
  }

  void _loadData() {
    _futureProfile =
        ProfileService.fetchProfile(widget.username).then((profile) {
      // seed follower count from server stats
      final stats = (profile['stats'] as Map<String, dynamic>?) ?? {};
      _followerCount = (stats['followers'] as int?) ?? 0;
      return profile;
    });

    _futureCreated =
        ItineraryService.fetchCreatedByUsername(widget.username);
    _futureSaved = ItineraryService.fetchSavedByUsername(widget.username);
  }

  Future<void> _refresh() async {
    setState(_loadData);
    _initFollowState();
    await Future.wait([_futureProfile, _futureCreated, _futureSaved]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // who am I? (Provider) — fall back to route arg if not set
    final me = context.watch<AuthStore?>()?.username ?? widget.currentUser;
    final viewingSelf = me == widget.username;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: NestedScrollView(
          headerSliverBuilder: (_, _) => [
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: const BackButton(color: Colors.white),
              flexibleSpace: FutureBuilder<Map<String, dynamic>>(
                future: _futureProfile,
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x99000000), Color(0x19000000)],
                        ),
                      ),
                    );
                  }
                  if (snap.hasError || !snap.hasData) {
                    return Center(
                      child: Text(
                        'Failed to load profile',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    );
                  }

                  // Unpack header payload
                  final p = snap.data!;
                  final uname = p['username'] as String? ?? widget.username;
                  final headerUrl = resolveImageRef(url: p['header_url'] as String?, name: p['header_name'] as String?);
                  final avatarUrl = resolveImageRef(url: p['avatar_url'] as String?, name: p['avatar_name'] as String?);
                  final bio = p['bio'] as String?;
                  final stats = p['stats'] as Map<String, dynamic>? ?? {};
                  final places = stats['places'] ?? 0;
                  final trips = stats['trips'] ?? 0;
                  final followers = _followerCount ?? (stats['followers'] ?? 0);

                  return FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (headerUrl != null)
                          imageFromRef(headerUrl, fit: BoxFit.cover),
                          // Image.network(headerUrl, fit: BoxFit.cover),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x99000000), Color(0x19000000)],
                            ),
                          ),
                        ),
                        if (avatarUrl != null)
                          Positioned(
                            bottom: 16,
                            left: 16,
                            child: CircleAvatar(
                              radius: 48,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 44,
                                backgroundImage: providerFromRef(avatarUrl),
                              ),
                            ),
                          ),

                        // Username & bio
                        Positioned(
                          bottom: 16 + 48 + 8,
                          left: 128,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                uname,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (bio != null && bio.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    bio,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Stats row
                        Positioned(
                          bottom: 16,
                          left: 128,
                          right: 16,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _Stat(label: 'Places', value: '$places'),
                              _Stat(label: 'Followers', value: '$followers'),
                              _Stat(label: 'Trips', value: '$trips'),
                            ],
                          ),
                        ),

                        // Follow / Following pill (only on other users' profiles)
                        if (!viewingSelf)
                          Positioned(
                            top: 44,
                            right: 16,
                            child: _FollowPill(
                              loading: _isFollowing == null,
                              isFollowing: _isFollowing ?? false,
                              onToggle: () async {
                                if (_isFollowing == null) return;
                                final wantFollow = !(_isFollowing!);

                                // optimistic UI
                                setState(() {
                                  _isFollowing = wantFollow;
                                  _followerCount =
                                      (_followerCount ?? 0) + (wantFollow ? 1 : -1);
                                  if ((_followerCount ?? 0) < 0) _followerCount = 0;
                                });

                                try {
                                  if (wantFollow) {
                                    await ProfileService.follow(me, widget.username);
                                  } else {
                                    await ProfileService.unfollow(me, widget.username);
                                  }
                                } catch (_) {
                                  // revert on failure
                                  setState(() {
                                    _isFollowing = !wantFollow;
                                    _followerCount =
                                        (_followerCount ?? 0) + (wantFollow ? -1 : 1);
                                    if ((_followerCount ?? 0) < 0) _followerCount = 0;
                                  });
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Could not update follow status.'),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Sticky tabs
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorWeight: 3,
                  labelColor: Colors.black87,
                  unselectedLabelColor: Colors.black54,
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  tabs: const [Tab(text: 'Created'), Tab(text: 'Saved')],
                ),
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              // CREATED
              FutureBuilder<List<Itinerary>>(
                future: _futureCreated,
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Text('Error: ${snap.error}', style: GoogleFonts.poppins()),
                    );
                  }
                  final list = snap.data ?? const <Itinerary>[];
                  if (list.isEmpty) {
                    return Center(
                      child: Text('No trips yet', style: GoogleFonts.poppins()),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _ItinCard(
                      itin: list[i],
                      trailing: null,
                    ),
                  );
                },
              ),

              // SAVED
              FutureBuilder<List<Itinerary>>(
                future: _futureSaved,
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Text('Error: ${snap.error}', style: GoogleFonts.poppins()),
                    );
                  }
                  final list = snap.data ?? const <Itinerary>[];
                  if (list.isEmpty) {
                    return Center(
                      child: Text('No saved trips yet', style: GoogleFonts.poppins()),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final itin = list[i];
                      return _ItinCard(
                        itin: itin,
                        // Only you can unsave from your own Saved tab
                        trailing: viewingSelf
                            ? IconButton(
                                tooltip: 'Unsave',
                                icon: const Icon(Icons.bookmark_remove),
                                onPressed: () async {
                                  await ProfileService.unsaveTrip(me, itin.id);
                                  setState(_loadData);
                                },
                              )
                            : null,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

}

/// Tiny stat pill used in the header.
class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

/// Follow / Following pill with loading state.
class _FollowPill extends StatelessWidget {
  final bool loading;
  final bool isFollowing;
  final VoidCallback onToggle;

  const _FollowPill({
    required this.loading,
    required this.isFollowing,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(isFollowing ? 'Following' : 'Follow');

    final style = OutlinedButton.styleFrom(
      backgroundColor:
          isFollowing ? Colors.white : Theme.of(context).primaryColor,
      foregroundColor: isFollowing ? Colors.black87 : Colors.white,
      side: BorderSide(color: Theme.of(context).primaryColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );

    return OutlinedButton(
      onPressed: loading ? null : onToggle,
      style: style,
      child: child,
    );
  }
}

class _ItinCard extends StatelessWidget {
  final Itinerary itin;
  final Widget? trailing;
  const _ItinCard({required this.itin, this.trailing});

  String _coverUrl() {
    // first image/photo across all days
    for (final d in itin.days) {
      for (final b in d.blocks) {
        final t = b.type.toLowerCase();
        if (t == 'image' || t == 'photo') return b.content;
      }
    }
    return 'https://via.placeholder.com/800x400';
  }

  @override
  Widget build(BuildContext context) {
    final cover = _coverUrl();

    return Card(
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/detail', arguments: itin.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // cover
            imageFromRef(cover, height: 140, width: double.infinity, fit: BoxFit.cover),
            // Image.network(
            //   cover,
            //   height: 140,
            //   width: double.infinity,
            //   fit: BoxFit.cover,
            //   errorBuilder: (_, __, ___) => Container(
            //     height: 140,
            //     color: Colors.grey.shade200,
            //     child: const Center(child: Icon(Icons.broken_image)),
            //   ),
            // ),
            // title row
            ListTile(
              title: Text(itin.title,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              trailing: trailing,
            ),
          ],
        ),
      ),
    );
  }
}