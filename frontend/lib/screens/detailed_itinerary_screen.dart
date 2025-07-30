// lib/screens/detailed_itinerary_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as amaps;
import '../models/itinerary.dart';
import '../services/itinerary_service.dart';

class DetailedItineraryScreen extends StatefulWidget {
  final int id;
  const DetailedItineraryScreen({Key? key, required this.id}) : super(key: key);

  @override
  State<DetailedItineraryScreen> createState() => _DetailedItineraryScreenState();
}

class _DetailedItineraryScreenState extends State<DetailedItineraryScreen> {
  late Future<Itinerary> _futureItin;

  @override
  void initState() {
    super.initState();
    _futureItin = ItineraryService.fetchDetail(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Itinerary>(
      future: _futureItin,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snap.error}')),
          );
        }
        final itin = snap.data!;
        return Scaffold(
          appBar: AppBar(
            title: Text(itin.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (itin.description.isNotEmpty) ...[
                Text(itin.description, style: GoogleFonts.poppins(fontSize: 16)),
                const SizedBox(height: 16),
              ],
              // Render each block according to its type
              ...itin.blocks.map((b) {
                switch (b.type) {
                  case 'text':
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        b.content,
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    );

                  case 'image':
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Image.network(
                        b.content,
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, prog) =>
                            prog == null ? child : const SizedBox(height: 150, child: Center(child: CircularProgressIndicator())),
                        errorBuilder: (ctx, _, __) => Container(
                          height: 150,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 40, color: Colors.black26),
                          ),
                        ),
                      ),
                    );

                  case 'map':
                    // parse "lat,lng"
                    final parts = b.content.split(',');
                    final lat = double.tryParse(parts[0]);
                    final lng = double.tryParse(parts[1]);
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
                            // Apple map preview
                            ? amaps.AppleMap(
                                initialCameraPosition: amaps.CameraPosition(
                                  target: amaps.LatLng(lat, lng),
                                  zoom: 14,
                                ),
                                annotations: {
                                  amaps.Annotation(
                                    annotationId: amaps.AnnotationId('${widget.id}-${b.hashCode}'),
                                    // some plugin versions use `position:` instead of `coordinate:`
                                    position: amaps.LatLng(lat, lng),
                                  )
                                },
                              )
                            // Google map preview
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
                                // omit removed params like zoomControlsEnabled
                              ),
                      ),
                    );

                  default:
                    return const SizedBox.shrink();
                }
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}