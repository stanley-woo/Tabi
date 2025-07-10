import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/itinerary.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _profileScreenState();
}

class _profileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabCtlr;

  final String _username = 'Sarah';
  final String _avatarUrl = 'https://i.pravatar.cc/150?img=5';

  // Mock data lists
  final List<Itinerary> _created = List.generate(
    3,
    (i) => Itinerary(
      id: 'c$i',
      title: 'My Trip #${i+1}',
      subtitle: '${4+i}D Adventure',
      imageUrl: 'https://picsum.photos/seed/c$i/400/200',
    ),
  );

  final List<Itinerary> _saved = List.generate(
    2,
    (i) => Itinerary(
      id: 'c$i',
      title: 'Saved Trip #${i+1}',
      subtitle: '${2+i}D Adventure',
      imageUrl: 'https://picsum.photos/seed/c$i/400/200',
    ),
  );

  @override
  void initState() {
    super.initState();
    _tabCtlr = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtlr.dispose();
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
          controller: _tabCtlr,
          indicatorColor: Theme.of(context).colorScheme.secondary,
          tabs: const [Tab(text: 'Created/Forked'), Tab(text: 'Saved')],
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

          Text('Travel Enthusiast', style: GoogleFonts.poppins(color: Colors.grey[600])),

          const SizedBox(height: 24),

          Expanded(
            child: TabBarView(
              controller: _tabCtlr,
              children: [
                _itineraryListView(_created),
                _itineraryListView(_saved),
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
        final it = list[i];
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/detail', arguments: it),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(12)),
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(it.imageUrl, height: 160, width: double.infinity, fit: BoxFit.cover),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(it.title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        );
      });
  }
}