import 'package:flutter/material.dart';
import '../models/itinerary.dart';
import '../demo/detailed_itinerary_demo.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  bool _showExplore = true;

  final List<Itinerary> _all = List.generate(
    5,
    (i) => Itinerary(
      id: 'saved$i',
      title: 'Trip #${i + 1}',
      subtitle: 'User${i + 1} • ${3 + i}D',
      imageUrl: 'https://picsum.photos/seed/$i/400/200',
      likes: 10 + i,
      saves: 5 + i,
      forks: 2 + i,
    ),
  );

  List<Itinerary> get _filtered {
    final query = _searchCtrl.text.toLowerCase();
    return _all.where((it) {
      final text = '${it.title} ${it.subtitle}'.toLowerCase();
      return text.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Itineraries'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search by location or Tag...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Explore / Following Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('Explore'), 
                selected: _showExplore,
                onSelected: (_) => setState(() => _showExplore = true),
              ),

              const SizedBox(width: 8),

              ChoiceChip(
                label: const Text('Following'), 
                selected: !_showExplore,
                onSelected: (_) => setState(() => _showExplore = false),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Feed list
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (ctx, i) {
                final it = _filtered[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      // Navigate to the detailed itinerary demo
                      Navigator.pushNamed(context, '/detail');
                      // Or push directly:
                      // Navigator.push(context,
                      //   MaterialPageRoute(builder: (_) => const DetailedItineraryDemo())
                      // );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(12),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.network(it.imageUrl, height: 180, width: double.infinity, fit: BoxFit.cover,),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(it.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(it.subtitle, style: const TextStyle(color: Colors.grey)),
                                  ],
                                ),

                                Row(
                                  children: [
                                    const Icon(Icons.favorite, size: 16, color: Colors.red),
                                    const SizedBox(width: 4),
                                    Text('${it.likes}'),
                                    const SizedBox(width: 12),

                                    const Icon(Icons.bookmark, size: 16),
                                    const SizedBox(width: 4),
                                    Text('${it.saves}'),
                                    const SizedBox(width: 12),

                                    const Icon(Icons.share, size: 16),
                                    const SizedBox(width: 4),
                                    Text('${it.forks}'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          )
        ],
      ),
      
      // Bottom navigation stub
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'You'),
        ],
        currentIndex: 0,
        onTap: (i) {
          if (i==2) Navigator.pushNamed(context, '/profile');
        },
      ),
    );
  }
}