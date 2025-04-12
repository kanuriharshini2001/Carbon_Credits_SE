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

    // Push to pendingRedemptions
    final ref = FirebaseDatabase.instance.ref("pendingRedemptions/${user.uid}");
    await ref.set({
      "email": user.email,
      "reward": reward,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    });

    // Deduct credits
    final userCreditsRef = FirebaseDatabase.instance.ref("users/${user.uid}/credits");
    await userCreditsRef.set(userCredits - cost);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Redemption request submitted")),
    );

    setState(() {
      userCredits -= cost;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Redeem Credits"), backgroundColor: Colors.purple),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: rewards.map((reward) {
          return Card(
            child: ListTile(
              title: Text(reward["label"]),
              subtitle: Text("${reward["cost"]} Credits"),
              trailing: ElevatedButton(
                onPressed: () => requestRedemption(reward["label"], reward["cost"]),
                child: const Text("Redeem"),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
