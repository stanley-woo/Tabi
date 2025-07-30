import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as amaps;

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

  gmaps.GoogleMapController? _gController;
  amaps.AppleMapController? _aController;

  @override
  void initState() {
    super.initState();
    _picked = widget.initialPosition ?? const LatLng(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick Location'), leading: BackButton(onPressed: () => Navigator.pop(context))),
      body: Stack(
        children: [
          Positioned.fill(child: Platform.isIOS ? _buildAppleMap() : _buildGoogleMap()),

          Center(child: const Icon(Icons.location_pin, size: 48, color: Colors.redAccent)),

          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () {
                Navigator.pop(context, _picked);
              },
              child: const Text('Confirm Location')
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGoogleMap() {
    final initial = gmaps.CameraPosition(target: gmaps.LatLng(widget.initialPosition?.latitude ?? 0, widget.initialPosition?.longitude ?? 0), zoom: 4);

    return gmaps.GoogleMap(
      initialCameraPosition: initial,
      onMapCreated: (ctrl) => _gController = ctrl,
      onCameraMove: (pos) {
        setState(() {
          _picked = LatLng(pos.target.latitude, pos.target.longitude);
        });
      },
    );
  }

  Widget _buildAppleMap() {
    final initial = amaps.CameraPosition(target: amaps.LatLng(widget.initialPosition?.latitude ?? 0, widget.initialPosition?.longitude ?? 0), zoom: 4);

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
}