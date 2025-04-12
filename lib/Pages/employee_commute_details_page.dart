import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class EmployeeCommuteDetailsPage extends StatelessWidget {
  final String uid;
  final String name;

  const EmployeeCommuteDetailsPage({
    super.key,
    required this.uid,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final DatabaseReference commuteRef =
    FirebaseDatabase.instance.ref("commutes/$uid");

    return Scaffold(
      appBar: AppBar(
        title: Text("$name's Commutes"),
        backgroundColor: Colors.purple,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: commuteRef.limitToLast(20).onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No commute records found."));
          }

          final data = Map<String, dynamic>.from(
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>);
          final commutes = data.values
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

          // Optional: sort by timestamp descending
          commutes.sort((a, b) =>
              b['timestamp'].toString().compareTo(a['timestamp'].toString()));

          return ListView.builder(
            itemCount: commutes.length,
            itemBuilder: (context, index) {
              final commute = commutes[index];
              final mode = commute['mode'] ?? 'unknown';
              final distance = commute['distance'] ?? 0;
              final credits = commute['creditsEarned'] ?? 0;
              final date = commute['timestamp']?.toString().split('T')[0] ?? '';

              return ListTile(
                leading: const Icon(Icons.directions_car, color: Colors.purple),
                title: Text("$mode - $distance mi"),
                subtitle: Text("Credits Earned: $credits"),
                trailing: Text(date),
              );
            },
          );
        },
      ),
    );
  }
}
