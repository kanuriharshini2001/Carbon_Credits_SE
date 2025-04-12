import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  GoogleMapController? mapController;
  LatLng _pickedLocation = const LatLng(37.4219999, -122.0840575);
  String _pickedAddress = "Select a location";

  void _onConfirm() {
    Navigator.pop(context, {
      "address": _pickedAddress,
      "coordinates": _pickedLocation,
    });
  }

  void _onTapMap(LatLng position) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    setState(() {
      _pickedLocation = position;
      _pickedAddress = placemarks.isNotEmpty
          ? "${placemarks.first.name}, ${placemarks.first.locality}"
          : "Unknown Address";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick a Location"),
        backgroundColor: Colors.purple,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickedLocation,
              zoom: 15,
            ),
            onMapCreated: (controller) => mapController = controller,
            onTap: _onTapMap,
            markers: {
              Marker(markerId: const MarkerId("picked"), position: _pickedLocation),
            },
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _onConfirm,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text("Confirm Location"),
            ),
          ),
        ],
      ),
    );
  }
}
