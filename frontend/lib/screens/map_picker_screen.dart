// ignore_for_file: unused_field

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as amaps;
import 'package:geolocator/geolocator.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialPosition;
  const MapPickerScreen({super.key, this.initialPosition});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class LatLng {
  final double latitude;
  final double longitude;
  const LatLng(this.latitude, this.longitude);
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng _picked;
  bool _isLoadingLocation = true;

  gmaps.GoogleMapController? _gController;
  amaps.AppleMapController? _aController;

  @override
  void initState() {
    super.initState();
    _picked = widget.initialPosition ?? const LatLng(0, 0);
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _picked = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      // Move Apple Map to current location
      if (_aController != null) {
        _aController!.animateCamera(
          amaps.CameraUpdate.newLatLng(
            amaps.LatLng(position.latitude, position.longitude),
          ),
        );
      }
    } catch (e) {
      print('Error getting location: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  Widget _buildLocationButton() {
    return Positioned(
      top: 16,
      right: 16,
      child: FloatingActionButton(
        mini: true,
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Widget _buildAppleMap() {
    final initial = amaps.CameraPosition(
      target: amaps.LatLng(_picked.latitude, _picked.longitude),
      zoom: 14,
    );

    return amaps.AppleMap(
      initialCameraPosition: initial,
      onMapCreated: (ctrl) => _aController = ctrl,
      onCameraMove: (pos) {
        setState(() {
          _picked = LatLng(pos.target.latitude, pos.target.longitude);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _isLoadingLocation
                ? const Center(child: CircularProgressIndicator())
                : _buildAppleMap(),
          ),
          Center(child: const Icon(Icons.location_pin, size: 48, color: Colors.redAccent)),
          _buildLocationButton(),
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context, _picked);
              },
              child: const Text('Confirm Location'),
            ),
          ),
        ],
      ),
    );
  }
}