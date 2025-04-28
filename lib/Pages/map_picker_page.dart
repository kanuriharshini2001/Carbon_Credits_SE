import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';

class MapPickerPage extends StatefulWidget {
  final bool isHome;
  final bool isOffice;

  const MapPickerPage({super.key, this.isHome = false, this.isOffice = false});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  GoogleMapController? _mapController;
  LatLng? _pickedLocation;
  String _pickedAddress = "Select a location";
  final TextEditingController _searchController = TextEditingController();
  late GooglePlace _googlePlace;
  List<AutocompletePrediction> predictions = [];

  @override
  void initState() {
    super.initState();
    _googlePlace = GooglePlace("API KEY:removed it as we made git public now");
    _setInitialPosition();
  }

  Future<void> _setInitialPosition() async {
    try {
      final status = await Geolocator.requestPermission();
      if (status == LocationPermission.denied ||
          status == LocationPermission.deniedForever) {
        debugPrint("Location permission denied");
        setState(() {
          _pickedLocation = LatLng(40.7128, -74.0060);
        });
        return;
      }

      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _pickedLocation = LatLng(pos.latitude, pos.longitude);
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(_pickedLocation!));
    } catch (e) {
      debugPrint("Error getting location: $e");
      setState(() {
        _pickedLocation = LatLng(40.7128, -74.0060); // fallback
      });
    }
  }

  Future<void> _onMapTap(LatLng latLng) async {
    String address = "Unknown Address";
    if (!kIsWeb) {
      try {
        final placemarks = await geo.placemarkFromCoordinates(
            latLng.latitude, latLng.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          address = "${place.name}, ${place.locality}";
        }
      } catch (e) {
        debugPrint("Placemark failed: $e");
      }
    }

    setState(() {
      _pickedLocation = latLng;
      _pickedAddress = address;
    });
  }

  Future<void> _onPlaceSelected(AutocompletePrediction p) async {
    final details = await _googlePlace.details.get(p.placeId!);
    if (details != null && details.result != null) {
      final lat = details.result!.geometry!.location!.lat!;
      final lng = details.result!.geometry!.location!.lng!;
      final pos = LatLng(lat, lng);

      _onMapTap(pos);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 15));
    }

    setState(() {
      predictions = [];
      _searchController.clear();
    });
  }

  void _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() => predictions = []);
      return;
    }

    final result = await _googlePlace.autocomplete.get(query);
    if (result != null && result.predictions != null) {
      setState(() => predictions = result.predictions!);
    }
  }

  Future<void> _onConfirm() async {
    if (_pickedLocation == null) return;

    final coords =
        "${_pickedLocation!.latitude}, ${_pickedLocation!.longitude}";
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final ref = FirebaseDatabase.instance.ref("users/${user.uid}");
      if (widget.isHome) {
        await ref.update(
            {"homeAddress": _pickedAddress, "homeCoords": coords});
      } else if (widget.isOffice) {
        await ref.update(
            {"officeLocation": _pickedAddress, "officeCoords": coords});
      }
    }

    Navigator.pop(context, {
      "address": _pickedAddress,
      "coordinates": _pickedLocation,
    });
  }

  Widget _buildSearchBar() {
    return Positioned(
      top: 20,
      left: 15,
      right: 15,
      child: Column(
        children: [
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: TextField(
              controller: _searchController,
              onChanged: _searchPlaces,
              decoration: InputDecoration(
                hintText: "Search location",
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: InputBorder.none,
              ),
            ),
          ),
          if (predictions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: predictions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(predictions[index].description ?? ""),
                    onTap: () => _onPlaceSelected(predictions[index]),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentLocationButton() {
    return Positioned(
      bottom: 80,
      right: 15,
      child: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: _setInitialPosition,
        child: const Icon(Icons.my_location, color: Colors.purple),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: ElevatedButton(
        onPressed: _onConfirm,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
        child: const Text("Confirm Location"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pickedLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target:
              _pickedLocation ?? LatLng(40.7128, -74.0060), // fallback
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController = controller,
            myLocationButtonEnabled: false,
            myLocationEnabled: true,
            markers: _pickedLocation != null
                ? {
              Marker(
                markerId: const MarkerId("picked"),
                position: _pickedLocation!,
              ),
            }
                : {},
            onTap: _onMapTap,
          ),
          _buildSearchBar(),
          _buildCurrentLocationButton(),
          _buildConfirmButton(),
        ],
      ),
    );
  }
}
