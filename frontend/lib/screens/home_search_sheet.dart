import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/itinerary.dart';
import '../services/itinerary_service.dart';
import '../services/profile_service.dart';
import '../navigation/profile_args.dart';

class HomeSearchSheet extends StatefulWidget {
  final String currentUser; // e.g., 'julieee_mun'
  final String? initialQuery; // prefill from Home

  const HomeSearchSheet({
    super.key,
    required this.currentUser,
    this.initialQuery,
  });

  @override
  State<HomeSearchSheet> createState() => _HomeSearchSheetState();
}

class _HomeSearchSheetState extends State<HomeSearchSheet>
    with TickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  late final TextEditingController _q =
      TextEditingController(text: widget.initialQuery ?? '');

  late Future<List<Itinerary>> _futureTrips = ItineraryService.fetchList();
  late Future<List<Map<String, dynamic>>> _futurePeople =
      ProfileService.listUsers();

  void _onChanged(String _) => setState(() {});

  @override
  void dispose() {
    _tabs.dispose();
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = const Radius.circular(16);

    return ClipRRect(
      borderRadius: BorderRadius.only(topLeft: radius, topRight: radius),
      child: Material(
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Padding(
            // ✅ prevent overflow when keyboard is visible
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max, // take available height
              children: [
                // Grab handle
                Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),

                // Search input + quick action
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    children: [
                      TextField(
                        controller: _q,
                        autofocus: true,
                        onChanged: _onChanged,
                        onSubmitted: (v) => Navigator.pop(context, v),
                        decoration: InputDecoration(
                          hintText: 'Search trips or people',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.arrow_outward),
                          label: const Text('Use this search'),
                          onPressed: () => Navigator.pop(context, _q.text),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tabs
                TabBar(
                  controller: _tabs,
                  labelStyle:
                      GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  labelColor: Colors.black87,
                  unselectedLabelColor: Colors.black45,
                  tabs: const [Tab(text: 'Trips'), Tab(text: 'People')],
                ),

                // ✅ Take remaining space; no fixed height
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _TripsPane(query: _q.text, futureTrips: _futureTrips),
                      _PeoplePane(
                        query: _q.text,
                        futurePeople: _futurePeople,
                        currentUser: widget.currentUser,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TripsPane extends StatelessWidget {
  final String query;
  final Future<List<Itinerary>> futureTrips;
  const _TripsPane({required this.query, required this.futureTrips});

  @override
  Widget build(BuildContext context) {
    final q = query.toLowerCase().trim();

    return FutureBuilder<List<Itinerary>>(
      future: futureTrips,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        var list = snap.data ?? const <Itinerary>[];
        if (q.isNotEmpty) {
          list = list
              .where((i) =>
                  i.title.toLowerCase().contains(q) ||
                  (i.tags ?? [])
                      .any((t) => t.toLowerCase().contains(q)))
              .toList();
        }
        if (list.isEmpty) {
          return const Center(child: Text('No trips match.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final itin = list[i];
            return ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.grey[100],
              title: Text(itin.title,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              subtitle: (itin.tags != null && itin.tags!.isNotEmpty)
                  ? Text('#${itin.tags!.join('  #')}')
                  : null,
              onTap: () {
                Navigator.pop(context); // close sheet
                Navigator.pushNamed(context, '/detail',
                    arguments: itin.id);
              },
            );
          },
        );
      },
    );
  }
}

class _PeoplePane extends StatefulWidget {
  final String query;
  final Future<List<Map<String, dynamic>>> futurePeople;
  final String currentUser;
  const _PeoplePane({
    required this.query,
    required this.futurePeople,
    required this.currentUser,
  });

  @override
  State<_PeoplePane> createState() => _PeoplePaneState();
}

class _PeoplePaneState extends State<_PeoplePane> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.query.toLowerCase().trim();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: widget.futurePeople,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        var people = snap.data ?? const <Map<String, dynamic>>[];
        if (q.isNotEmpty) {
          people = people.where((u) {
            final uname = (u['username'] ?? '').toString().toLowerCase();
            final dname =
                (u['display_name'] ?? '').toString().toLowerCase();
            return uname.contains(q) || dname.contains(q);
          }).toList();
        }

        people = people.where((u) => (u['username'] ?? '').toString().toLowerCase() != widget.currentUser.toLowerCase()).toList();

        if (people.isEmpty) {
          return const Center(child: Text('No people match.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: people.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final u = people[i];
            final avatar = (u['avatar_url'] ?? u['avatar_name'])?.toString();
            final username = u['username'] as String;

            return ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.grey[100],
              leading: CircleAvatar(
                backgroundImage:
                    (avatar != null && avatar.isNotEmpty)
                        ? NetworkImage(avatar)
                        : null,
                child: (avatar == null || avatar.isEmpty)
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(
                (u['display_name'] as String?) ?? username,
                style:
                    GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('@$username'),
              trailing: _busy
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      tooltip: 'Follow',
                      icon: const Icon(Icons.person_add_alt_1),
                      onPressed: () async {
                        if (username == widget.currentUser) return;
                        setState(() => _busy = true);
                        try {
                          await ProfileService.follow(
                              widget.currentUser, username);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Following @$username')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _busy = false);
                        }
                      },
                    ),
              onTap: () {
                Navigator.pop(context); // close sheet
                Navigator.pushNamed(
                  context,
                  '/profile',
                  arguments:
                      ProfileArgs(username, widget.currentUser),
                );
              },
            );
          },
        );
      },
    );
  }
}