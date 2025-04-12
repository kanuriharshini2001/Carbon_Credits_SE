import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class RedemptionRequestsPage extends StatelessWidget {
  const RedemptionRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance.ref("pendingRedemptions");

    return Scaffold(
      appBar: AppBar(title: const Text("Redemption Approvals"), backgroundColor: Colors.purple),
      body: StreamBuilder(
        stream: ref.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: Text("No pending requests."));
          }

          final Map data = snapshot.data!.snapshot.value as Map;
          final entries = data.entries.toList();

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final request = entries[index];
              final uid = request.key;
              final reward = request.value["reward"];
              final userEmail = request.value["email"];
              final timestamp = request.value["timestamp"];

              return ListTile(
                title: Text("$userEmail → $reward"),
                subtitle: Text("Requested on ${DateTime.fromMillisecondsSinceEpoch(timestamp)}"),
                trailing: ElevatedButton(
                  onPressed: () async {
                    final userRef = FirebaseDatabase.instance.ref("redemptions/$uid").push();
                    await userRef.set({
                      "reward": reward,
                      "status": "Approved",
                      "timestamp": DateTime.now().millisecondsSinceEpoch,
                    });

                    await ref.child(uid!).remove();
                  },
                  child: const Text("Approve"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
