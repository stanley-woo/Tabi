// File: lib/screens/detailed_itinerary_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/navigation/create_itinerary_args.dart';
import 'package:frontend/widgets/image_ref.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as amaps;
import 'package:provider/provider.dart';

import '../state/auth_store.dart';
import '../models/itinerary.dart';
import '../services/itinerary_service.dart';
import '../services/profile_service.dart';

class DetailedItineraryScreen extends StatefulWidget {
  final int id;
  final String? currentUser; // CHANGED: optional (Provider is the source of truth)

  const DetailedItineraryScreen({
    super.key,
    required this.id,
    this.currentUser,
  });

  @override
  State<DetailedItineraryScreen> createState() => _DetailedItineraryScreenState();
}

class _DetailedItineraryScreenState extends State<DetailedItineraryScreen> {
  late Future<Itinerary> _futureItinerary;
  bool _saved = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _futureItinerary = ItineraryService.fetchDetail(widget.id);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initSaved(); // NEW: can safely read Provider here
  }

  /// Resolve current user from Provider; fall back to widget.currentUser if provided.
  String? _me(BuildContext context) {
    final fromProvider = context.read<AuthStore?>()?.username; // NEW
    return fromProvider ?? widget.currentUser;
  }

  Future<void> _initSaved() async {
    final me = _me(context);
    if (me == null) return; // not logged in; skip saved-state check
    try {
      final v = await ProfileService.isTripSaved(me, widget.id);
      if (mounted) setState(() => _saved = v);
    } catch (_) {/* ignore */}
  }

  Future<void> _toggleSave() async {
    final me = _me(context);
    if (me == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save trips.')),
      );
      return;
    }
    if (_busy) return;

    setState(() => _busy = true);
    try {
      if (_saved) {
        await ProfileService.unsaveTrip(me, widget.id);
        if (mounted) setState(() => _saved = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from Saved')),
          );
        }
      } else {
        await ProfileService.saveTrip(me, widget.id);
        if (mounted) setState(() => _saved = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved to your profile')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Itinerary>(
      future: _futureItinerary,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Scaffold(body: Center(child: Text('Error: ${snap.error}')));
        }

        final itin = snap.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(itin.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            actions: [
              IconButton(
                tooltip: _saved ? 'Unsave' : 'Save',
                onPressed: _busy ? null : _toggleSave,
                icon: Icon(_saved ? Icons.bookmark : Icons.bookmark_outline),
                color: _saved ? Theme.of(context).primaryColor : null,
              ),
              IconButton(
                tooltip: 'Fork',
                icon: const Icon(Icons.fork_right),
                onPressed: () {
                  final it = itin;
                  Navigator.pushNamed(context, '/create', arguments: CreateItineraryArgs(template: it));
                },
              )
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (itin.description.isNotEmpty) ...[
                Text(itin.description, style: GoogleFonts.poppins(fontSize: 16)),
                const SizedBox(height: 24),
              ],

              ...itin.days.map((day) {
                // Safe date formatting whether String or DateTime
                final d = day.date;
                // ignore: unnecessary_type_check
                final String dateStr = (d is DateTime)
                    ? d.toIso8601String().substring(0, 10)
                    : (d.toString().length >= 10 ? d.toString().substring(0, 10) : d.toString());

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${day.title ?? 'Day ${day.order}'} •  $dateStr',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),

                    ...day.blocks.map((b) {
                      switch (b.type) {
                        case 'text':
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(b.content, style: GoogleFonts.poppins(fontSize: 14)),
                          );

                        case 'image':
                        case 'photo': // accept both
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: imageFromRef(b.content, height: 180, width: double.infinity, fit: BoxFit.cover),
                            // child: Image.network(
                            //   b.content,
                            //   fit: BoxFit.cover,
                            //   loadingBuilder: (ctx, child, prog) =>
                            //       prog == null ? child : const SizedBox(
                            //         height: 150,
                            //         child: Center(child: CircularProgressIndicator()),
                            //       ),
                            //   errorBuilder: (ctx, _, __) => Container(
                            //     height: 150,
                            //     color: Colors.grey.shade200,
                            //     child: const Center(
                            //       child: Icon(Icons.broken_image, size: 40, color: Colors.black26),
                            //     ),
                            //   ),
                            // ),
                          );

                        case 'map':
                          final parts = b.content.split(',');
                          final lat = double.tryParse(parts[0]);
                          final lng = double.tryParse(parts.length > 1 ? parts[1] : '');
                          if (lat == null || lng == null) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('Invalid location: ${b.content}',
                                  style: GoogleFonts.poppins(color: Colors.red)),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: SizedBox(
                              height: 150,
                              child: Platform.isIOS
                                  ? amaps.AppleMap(
                                      initialCameraPosition: amaps.CameraPosition(
                                        target: amaps.LatLng(lat, lng),
                                        zoom: 14,
                                      ),
                                      annotations: {
                                        amaps.Annotation(
                                          annotationId: amaps.AnnotationId('${widget.id}-${b.hashCode}'),
                                          position: amaps.LatLng(lat, lng),
                                        )
                                      },
                                    )
                                  : gmaps.GoogleMap(
                                      initialCameraPosition: gmaps.CameraPosition(
                                        target: gmaps.LatLng(lat, lng),
                                        zoom: 14,
                                      ),
                                      markers: {
                                        gmaps.Marker(
                                          markerId: gmaps.MarkerId('${widget.id}-${b.hashCode}'),
                                          position: gmaps.LatLng(lat, lng),
                                        )
                                      },
                                    ),
                            ),
                          );

                        default:
                          return const SizedBox.shrink();
                      }
                    }),

                    const SizedBox(height: 32),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }
}