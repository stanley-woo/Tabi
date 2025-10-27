// File: lib/screens/detailed_itinerary_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/navigation/create_itinerary_args.dart';
import 'package:frontend/widgets/image_ref.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as amaps;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../state/auth_store.dart';
import '../models/itinerary.dart';
import '../services/itinerary_service.dart';
import '../services/profile_service.dart';

class DetailedItineraryScreen extends StatefulWidget {
  final int id;
  final String? currentUser;

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
    _initSaved();
  }

  /// Resolve current user from Provider; fall back to widget.currentUser if provided.
  String? _me(BuildContext context) {
    final fromProvider = context.read<AuthStore?>()?.username; // NEW
    return fromProvider ?? widget.currentUser;
  }

  int? _meId(BuildContext context) {
    final fromProvider = context.read<AuthStore?>()?.userId;
    return fromProvider ?? int.tryParse(widget.currentUser ?? '');
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

  Future<void> _deleteItinerary() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Itinerary'),
        content: const Text('Are you sure you want to delete this itinerary? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ItineraryService.deleteItinerary(widget.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Itinerary deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete itinerary: $e')),
          );
        }
      }
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
              ),
              if (itin.creatorId == _meId(context)) ...[
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.pushNamed(context, '/create', arguments: CreateItineraryArgs(template: itin));
                  },
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteItinerary,
                ),
              ],
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (itin.description.isNotEmpty) ...[
                  Card(
                    elevation: 2, // Controls the shadow intensity
                    margin: const EdgeInsets.only(bottom: 24), // Add space below the card
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal.withAlpha(13),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trip Overview',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            itin.description,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              height: 1.5, // Improves readability for multi-line text
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                            child: MarkdownBody(
                              data: b.content,
                              styleSheet: MarkdownStyleSheet(
                                p: GoogleFonts.poppins(fontSize: 14),
                                h1: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                                h2: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                                h3: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                                strong: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                                em: GoogleFonts.poppins(fontStyle: FontStyle.italic),
                              ),
                              selectable: true,
                            ),
                          );

                        case 'image':
                        case 'photo': // accept both
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog(
                                    child: Container(
                                      constraints: const BoxConstraints(maxWidth: double.infinity, maxHeight: double.infinity),
                                      child: InteractiveViewer(
                                        minScale: 0.5,
                                        maxScale: 4.0,
                                        child: imageFromRef(b.content, height: double.infinity, width: double.infinity, fit: BoxFit.contain),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: imageFromRef(b.content, height: 180, width: double.infinity, fit: BoxFit.cover),
                            ),
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
                            child: Stack(
                              children: [
                                SizedBox(
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
                                // Overlay tapable area
                                Positioned.fill(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () async {
                                        // Open location in Apple Maps
                                        final Uri mapsUri = Uri.parse('http://maps.apple.com/?q=$lat,$lng');
                                        
                                        try {
                                          if (await canLaunchUrl(mapsUri)) {
                                            await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
                                          } else {
                                            // Fallback: Try without external mode
                                            await launchUrl(mapsUri);
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Could not open maps')),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
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