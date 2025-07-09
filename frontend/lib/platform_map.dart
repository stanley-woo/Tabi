import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as amap;

/// A platform-adaptive map that shows Google Maps on Android
/// and Apple Maps on iOS with a single marker at the given lat/lng.
class PlatformMap extends StatelessWidget {
  final double lat;
  final double lng;
  final String markerTitle;

  const PlatformMap({
    super.key,
    required this.lat,
    required this.lng,
    this.markerTitle = '',
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildAppleMap();
    } else {
      return _buildGoogleMap();
    }
  }

  /// Builds Google Map for Android
  Widget _buildGoogleMap() {
    return gmap.GoogleMap(
      initialCameraPosition: gmap.CameraPosition(
        target: gmap.LatLng(lat, lng),
        zoom: 14,
      ),
      markers: {
        gmap.Marker(
          markerId: const gmap.MarkerId('marker'),
          position: gmap.LatLng(lat, lng),
          infoWindow: gmap.InfoWindow(title: markerTitle),
        ),
      },
      zoomControlsEnabled: true,
      myLocationButtonEnabled: false,
    );
  }

  /// Builds Apple Map for iOS
  Widget _buildAppleMap() {
    return amap.AppleMap(
      initialCameraPosition: amap.CameraPosition(
        target: amap.LatLng(lat, lng),
        zoom: 14,
      ),
      annotations: {
        amap.Annotation(
          annotationId: amap.AnnotationId('marker'),
          position: amap.LatLng(lat, lng),
          infoWindow: amap.InfoWindow(title: markerTitle),
        ),
      },
    );
  }
}