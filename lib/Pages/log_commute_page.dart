import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'map_picker_page.dart';

class LogCommutePage extends StatefulWidget {
  const LogCommutePage({super.key});

  @override
  State<LogCommutePage> createState() => _LogCommutePageState();
}

class _LogCommutePageState extends State<LogCommutePage> {
  String? fromAddress;
  String? toAddress;
  String? fromCoordinates;
  String? toCoordinates;

  double calculatedDistance = 0.0;
  String selectedMode = "carpool";
  final List<String> modes = ["carpool", "public", "wfh", "private"];
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int getPointsForMode(String mode) {
    switch (mode) {
      case "carpool":
        return 2;
      case "public":
        return 3;
      case "wfh":
        return 4;
      default:
        return 0;
    }
  }

  Future<void> submitCommute() async {
    if (fromAddress == null || toAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select both locations")),
      );
      return;
    }

    final startLatLng = fromCoordinates!.split(',').map((e) => double.parse(e.trim())).toList();
    final endLatLng = toCoordinates!.split(',').map((e) => double.parse(e.trim())).toList();

    double distance = Geolocator.distanceBetween(
      startLatLng[0], startLatLng[1], endLatLng[0], endLatLng[1],
    ) / 1609.34; // meters to miles

    setState(() {
      calculatedDistance = distance;
    });

    int credits = (distance * getPointsForMode(selectedMode)).toInt();

    final user = _auth.currentUser;
    if (user == null) return;

    // Save to Realtime Database
    final commuteRef = FirebaseDatabase.instance.ref("commutes/${user.uid}").push();
    await commuteRef.set({
      "fromAddress": fromAddress,
      "toAddress": toAddress,
      "fromCoords": fromCoordinates,
      "toCoords": toCoordinates,
      "mode": selectedMode,
      "miles": distance,
      "credits": credits,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    });

    // Update total user credits
    final userRef = FirebaseDatabase.instance.ref("users/${user.uid}/credits");
    final snapshot = await userRef.get();
    final existingCredits = (snapshot.value as int?) ?? 0;
    await userRef.set(existingCredits + credits);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Commute submitted!")));

    setState(() {
      fromAddress = null;
      toAddress = null;
      fromCoordinates = null;
      toCoordinates = null;
      calculatedDistance = 0.0;
    });
  }

  Future<void> pickLocation(bool isFrom) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerPage()),
    );

    if (result != null) {
      final address = result["address"];
      final coords = result["coordinates"];
      final formattedCoords = "${coords.latitude}, ${coords.longitude}";

      setState(() {
        if (isFrom) {
          fromAddress = address;
          fromCoordinates = formattedCoords;
        } else {
          toAddress = address;
          toCoordinates = formattedCoords;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Log Your Commute"), backgroundColor: Colors.purple),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          ListTile(
            leading: const Icon(Icons.location_pin),
            title: Text(fromAddress ?? "Select From Location"),
            trailing: ElevatedButton(
              onPressed: () => pickLocation(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text("Pick"),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.location_pin),
            title: Text(toAddress ?? "Select To Location"),
            trailing: ElevatedButton(
              onPressed: () => pickLocation(false),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text("Pick"),
            ),
          ),
          const SizedBox(height: 10),
          Text("Distance: ${calculatedDistance.toStringAsFixed(2)} miles",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedMode,
            items: modes.map((mode) => DropdownMenuItem(value: mode, child: Text(mode.toUpperCase()))).toList(),
            onChanged: (value) => setState(() => selectedMode = value!),
            decoration: const InputDecoration(labelText: "Mode of Transport"),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: submitCommute,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text("Submit Commute", style: TextStyle(color: Colors.white)),
          ),
        ]),
      ),
    );
  }
}
