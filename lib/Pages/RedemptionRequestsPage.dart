import 'package:flutter/material.dart';
<<<<<<< HEAD
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
=======
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class RedemptionRequestsPage extends StatefulWidget {
  const RedemptionRequestsPage({super.key});

  @override
  State<RedemptionRequestsPage> createState() => _RedemptionRequestsPageState();
}

class _RedemptionRequestsPageState extends State<RedemptionRequestsPage> {
  bool isEmployer = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    checkEmployerRole();
  }

  Future<void> checkEmployerRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instance.ref("users/${user.uid}/role");
    final snapshot = await ref.get();

    setState(() {
      isEmployer = snapshot.value == "employer";
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!isEmployer) {
      return const Scaffold(
        body: Center(child: Text("Access denied. You must be an employer.")),
      );
    }

    final ref = FirebaseDatabase.instance.ref("pendingRedemptions");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Redemption Approvals"),
        backgroundColor: Colors.purple,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: ref.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No pending requests."));
          }

          final Map data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
>>>>>>> master
          final entries = data.entries.toList();

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final request = entries[index];
<<<<<<< HEAD
              final uid = request.key;
              final reward = request.value["reward"];
              final userEmail = request.value["email"];
              final timestamp = request.value["timestamp"];
=======
              final requestData = Map<String, dynamic>.from(request.value);
              final reward = requestData["reward"];
              final userEmail = requestData["email"];
              final userId = requestData["uid"];
              final timestamp = requestData["timestamp"];
>>>>>>> master

              return ListTile(
                title: Text("$userEmail → $reward"),
                subtitle: Text("Requested on ${DateTime.fromMillisecondsSinceEpoch(timestamp)}"),
                trailing: ElevatedButton(
                  onPressed: () async {
<<<<<<< HEAD
                    final userRef = FirebaseDatabase.instance.ref("redemptions/$uid").push();
                    await userRef.set({
                      "reward": reward,
                      "status": "Approved",
                      "timestamp": DateTime.now().millisecondsSinceEpoch,
                    });

                    await ref.child(uid!).remove();
=======
                    try {
                      final approvedRef = FirebaseDatabase.instance.ref("redemptions/$userId").push();
                      await approvedRef.set({
                        "reward": reward,
                        "status": "Approved",
                        "timestamp": DateTime.now().millisecondsSinceEpoch,
                      });

                      await ref.child(request.key).remove();

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Redemption approved.")),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: ${e.toString()}")),
                      );
                    }
>>>>>>> master
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
