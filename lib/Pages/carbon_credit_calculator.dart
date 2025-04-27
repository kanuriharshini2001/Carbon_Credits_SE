import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

Future<Map<String, double>> calculateCarbonCreditsWithModes() async {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final DatabaseReference commutesRef = FirebaseDatabase.instance.ref("commutes/$uid");

  final snapshot = await commutesRef.get();

  double carpoolMiles = 0.0;
  double publicMiles = 0.0;
  double wfhMiles = 0.0;

  if (snapshot.exists) {
    final Map data = Map.from(snapshot.value as Map);

    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    data.forEach((key, commute) {
      final commuteData = Map<String, dynamic>.from(commute);
      final timestamp = commuteData["timestamp"];
      final travelMode = commuteData["mode"]; // ← make sure it's "mode", not "travelMode"
      final miles = double.tryParse(commuteData["miles"].toString()) ?? 0;

      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (date.month == currentMonth && date.year == currentYear) {
        switch (travelMode) {
          case "carpool":
            carpoolMiles += miles;
            break;
          case "public":
            publicMiles += miles;
            break;
          case "work_from_home":
            wfhMiles += miles;
            break;
        }
      }
    });
  }

  final double totalEcoMiles = carpoolMiles + publicMiles + wfhMiles;

  return {
    "carpool": carpoolMiles,
    "public": publicMiles,
    "wfh": wfhMiles,
    "total": totalEcoMiles,
  };
}
