import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class RedeemCreditsPage extends StatefulWidget {
  const RedeemCreditsPage({super.key});

  @override
  State<RedeemCreditsPage> createState() => _RedeemCreditsPageState();
}

class _RedeemCreditsPageState extends State<RedeemCreditsPage> {
  final List<Map<String, dynamic>> rewards = [
    {"label": "Coffee Voucher", "cost": 20},
    {"label": "Movie Ticket", "cost": 50},
    {"label": "Gift Card", "cost": 100},
  ];

  int userCredits = 0;

  @override
  void initState() {
    super.initState();
    fetchCredits();
  }

  void fetchCredits() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instance.ref("users/${user.uid}/credits");
    final snapshot = await ref.get();
    if (snapshot.exists) {
      setState(() {
        userCredits = (snapshot.value as int?) ?? 0;
      });
    }
  }

  void requestRedemption(String reward, int cost) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (userCredits < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not enough credits")),
      );
      return;
    }

    try {
      final ref = FirebaseDatabase.instance.ref("pendingRedemptions").push();
      await ref.set({
        "uid": user.uid,
        "email": user.email,
        "reward": reward,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      });

      final userCreditsRef = FirebaseDatabase.instance.ref("users/${user.uid}/credits");
      await userCreditsRef.set(userCredits - cost);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Redemption request for $reward submitted.")),
      );

      setState(() {
        userCredits -= cost;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting redemption: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Redeem Credits"),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.credit_score, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  "You have $userCredits credits",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: rewards.length,
              itemBuilder: (context, index) {
                final reward = rewards[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(reward["label"]),
                    subtitle: Text("${reward["cost"]} Credits"),
                    trailing: ElevatedButton(
                      onPressed: () => requestRedemption(reward["label"], reward["cost"]),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text("Redeem"),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
