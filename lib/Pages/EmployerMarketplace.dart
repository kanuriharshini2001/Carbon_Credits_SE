import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class EmployerMarketplacePage extends StatefulWidget {
  const EmployerMarketplacePage({super.key});

  @override
  State<EmployerMarketplacePage> createState() => _EmployerMarketplacePageState();
}

class _EmployerMarketplacePageState extends State<EmployerMarketplacePage> {
  final TextEditingController _buyController = TextEditingController();
  final TextEditingController _sellController = TextEditingController();

  int availableCredits = 0;
  int marketplaceCredits = 0;
  bool loading = true;

  final String marketplaceNode = "marketplace_pool";

  @override
  void initState() {
    super.initState();
    fetchCredits();
  }

  Future<void> fetchCredits() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseDatabase.instance.ref("users/${user.uid}/credits");
    final marketRef = FirebaseDatabase.instance.ref(marketplaceNode);

    final userSnap = await userRef.get();
    final marketSnap = await marketRef.get();

    setState(() {
      availableCredits = (userSnap.value as int?) ?? 0;
      marketplaceCredits = (marketSnap.value as int?) ?? 0;
      loading = false;
    });
  }

  Future<void> updateEmployerCredits(int delta) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instance.ref("users/${user.uid}/credits");
    final currentSnap = await ref.get();
    final current = (currentSnap.value as int?) ?? 0;

    final newTotal = current + delta;
    if (newTotal < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not enough credits to sell.")),
      );
      return;
    }

    await ref.set(newTotal);
    setState(() {
      availableCredits = newTotal;
    });
  }

  Future<void> updateMarketplaceCredits(int delta) async {
    final ref = FirebaseDatabase.instance.ref(marketplaceNode);
    final currentSnap = await ref.get();
    final current = (currentSnap.value as int?) ?? 0;

    final newTotal = current + delta;
    if (newTotal < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Marketplace has insufficient credits.")),
      );
      return;
    }

    await ref.set(newTotal);
    setState(() {
      marketplaceCredits = newTotal;
    });
  }

  void handleBuy() async {
    final credits = int.tryParse(_buyController.text.trim()) ?? 0;
    if (credits <= 0) return;

    // ✅ Max buy limit
    if (credits > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can’t buy more than 500 credits at once.")),
      );
      return;
    }

    // ✅ Pool buffer check
    if (marketplaceCredits - credits < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Marketplace must retain at least 100 credits.")),
      );
      return;
    }

    await updateEmployerCredits(credits);
    await updateMarketplaceCredits(-credits);
    _buyController.clear();
  }

  void handleSell() async {
    final credits = int.tryParse(_sellController.text.trim()) ?? 0;
    if (credits <= 0) return;

    if (availableCredits >= credits) {
      await updateEmployerCredits(-credits);
      await updateMarketplaceCredits(credits);
      _sellController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You don't have enough credits.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Text("Your Available Credits", style: TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            Text(
              "$availableCredits pts",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 30),
            const Text("🌍 Marketplace Pool Balance", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text(
              "$marketplaceCredits pts",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const Divider(height: 40),
            const Text("Buy Carbon Credits", style: TextStyle(fontSize: 18)),
            TextField(
              controller: _buyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: "Enter credits to buy"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: handleBuy,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Buy"),
            ),
            const Divider(height: 40),
            const Text("Sell Carbon Credits", style: TextStyle(fontSize: 18)),
            TextField(
              controller: _sellController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: "Enter credits to sell"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: handleSell,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Sell"),
            ),
          ],
        ),
      ),
    );
  }
}
