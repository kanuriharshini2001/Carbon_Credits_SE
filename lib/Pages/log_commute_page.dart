import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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

  String? homeAddress;
  String? officeLocation;
  String? homeCoords;
  String? officeCoords;

  double calculatedDistance = 0.0;
  String selectedMode = "carpool";
  final List<String> modes = ["carpool", "public", "wfh", "private"];
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    fetchUserAddresses();
  }

  Future<void> fetchUserAddresses() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instance.ref("users/${user.uid}");
    final snapshot = await ref.get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        homeAddress = data["homeAddress"];
        homeCoords = data["homeCoords"];
        officeLocation = data["officeLocation"];
        officeCoords = data["officeCoords"];
      });
    }
  }

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
    ) / 1609.34;

    setState(() {
      calculatedDistance = distance;
    });

    int credits = (distance * getPointsForMode(selectedMode)).toInt();

    final user = _auth.currentUser;
    if (user == null) return;

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
      MaterialPageRoute(
        builder: (_) => MapPickerPage(
          isHome: false,
          isOffice: false,
        ),
      ),
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

  void setFromShortcut(bool isFrom, String label, String coords) {
    setState(() {
      if (isFrom) {
        fromAddress = label;
        fromCoordinates = coords;
      } else {
        toAddress = label;
        toCoordinates = coords;
      }
    });
  }

  Widget buildShortcutCard({
    required IconData icon,
    required String label,
    required String? address,
    required String? coords,
    required bool isFrom,
  }) {
    if (address == null || coords == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => setFromShortcut(isFrom, address, coords),
      child: Card(
        child: ListTile(
          leading: Icon(icon, color: Colors.purple),
          title: Text(label),
          subtitle: Text(address),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Log Your Commute"),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildShortcutCard(
              icon: Icons.home,
              label: "Home Address",
              address: homeAddress,
              coords: homeCoords,
              isFrom: true,
            ),
            buildShortcutCard(
              icon: Icons.work,
              label: "Office Location",
              address: officeLocation,
              coords: officeCoords,
              isFrom: false,
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(fromAddress ?? "Select From Location"),
              trailing: ElevatedButton(
                onPressed: () => pickLocation(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: const Text("Pick"),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(toAddress ?? "Select To Location"),
              trailing: ElevatedButton(
                onPressed: () => pickLocation(false),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: const Text("Pick"),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Distance: ${calculatedDistance.toStringAsFixed(2)} miles",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedMode,
              items: modes
                  .map((mode) =>
                  DropdownMenuItem(value: mode, child: Text(mode.toUpperCase())))
                  .toList(),
              onChanged: (value) => setState(() => selectedMode = value!),
              decoration: const InputDecoration(labelText: "Mode of Transport"),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: submitCommute,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: const Text("Submit Commute", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
