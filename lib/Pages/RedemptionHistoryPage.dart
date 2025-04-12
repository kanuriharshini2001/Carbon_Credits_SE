import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class RedemptionHistoryPage extends StatelessWidget {
  const RedemptionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final ref = FirebaseDatabase.instance.ref("pendingRedemptions/${user?.uid}");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Redemption History"),
        backgroundColor: Colors.purple,
      ),
      body: StreamBuilder(
        stream: ref.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: Text("No redemption requests found."));
          }

          final Map data = snapshot.data!.snapshot.value as Map;
          final entries = data.entries.toList();

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final redemption = entries[index].value;
              final reward = redemption["reward"];
              final timestamp = redemption["timestamp"];
              final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
              final formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

              return ListTile(
                leading: const Icon(Icons.redeem, color: Colors.green),
                title: Text(reward ?? "Unknown"),
                subtitle: Text("Requested on: $formattedDate"),
              );
            },
          );
        },
      ),
    );
  }
}
