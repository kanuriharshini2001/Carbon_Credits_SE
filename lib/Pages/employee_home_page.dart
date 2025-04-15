import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'log_commute_page.dart';
<<<<<<< HEAD
=======
import 'RedeemCreditsPage.dart';
>>>>>>> master
import 'package:android_uber/auth/sigin_page.dart';

class EmployeeHomePage extends StatefulWidget {
  const EmployeeHomePage({super.key});

  @override
  State<EmployeeHomePage> createState() => _EmployeeHomePageState();
}

class _EmployeeHomePageState extends State<EmployeeHomePage> {
  int _selectedIndex = 0;
  int totalCredits = 0;

  @override
  void initState() {
    super.initState();
    fetchTotalCredits();
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void fetchTotalCredits() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instance.ref("users/${user.uid}/credits");
    final snapshot = await ref.get();

    setState(() {
      totalCredits = (snapshot.value as int?) ?? 0;
    });
  }

<<<<<<< HEAD
  Future<void> redeemCredits(int amountToRedeem) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseDatabase.instance.ref("users/${user.uid}/credits");
    final snapshot = await userRef.get();
    final currentCredits = (snapshot.value as int?) ?? 0;

    if (currentCredits >= amountToRedeem) {
      await userRef.set(currentCredits - amountToRedeem);

      await FirebaseDatabase.instance
          .ref("redemptions/${user.uid}")
          .push()
          .set({
        "amount": amountToRedeem,
        "status": "Pending",
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Redeemed $amountToRedeem credits successfully!")),
      );

      fetchTotalCredits();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not enough credits to redeem.")),
      );
    }
  }

  void showRedeemDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Redeem Your Credits"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("You have $totalCredits credits."),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  redeemCredits(50);
                  Navigator.pop(context);
                },
                child: const Text("Redeem 50 Credits for ₹50 Gift Card"),
              ),
            ],
          ),
        );
      },
    );
  }

=======
>>>>>>> master
  Widget _dashboardTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Total Credits: $totalCredits",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("Log Commute"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LogCommutePage()),
              );
              fetchTotalCredits();
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.redeem),
            label: const Text("Redeem Credits"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
<<<<<<< HEAD
            onPressed: showRedeemDialog,
=======
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RedeemCreditsPage()),
              );
            },
>>>>>>> master
          ),
        ],
      ),
    );
  }

  Widget _creditsLogTab() {
    final user = FirebaseAuth.instance.currentUser;
    final ref = FirebaseDatabase.instance.ref("commutes/${user?.uid}");

    return StreamBuilder(
      stream: ref.onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const Center(child: Text("No commute records found."));
        }

        final Map data = snapshot.data!.snapshot.value as Map;
        final entries = data.entries.toList();

        return ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final commute = entries[index].value;
            final miles = commute["miles"];
            final credits = commute["credits"];
            final mode = commute["mode"];

            String formattedDate = "Unknown";
            final rawTimestamp = commute["timestamp"];
            if (rawTimestamp is int) {
              final dt = DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
              formattedDate = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
            }

            return ListTile(
              leading: const Icon(Icons.directions_bus),
              title: Text("${mode ?? "Unknown"} - ${credits ?? 0} credits"),
              subtitle: Text("Miles: ${miles != null ? miles.toStringAsFixed(2) : "N/A"}"),
              trailing: Text(formattedDate),
            );
          },
        );
      },
    );
  }

  Widget _profileTab() {
    final user = FirebaseAuth.instance.currentUser;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person, size: 60, color: Colors.purple),
          const SizedBox(height: 10),
          const Text("Logged in as", style: TextStyle(fontSize: 16)),
          Text(user?.email ?? "No email", style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const SignInPage()),
                    (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text("Logout"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [_dashboardTab(), _creditsLogTab(), _profileTab()];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Portal"),
        backgroundColor: Colors.purple,
      ),
      body: tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.purple,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.eco),
            label: "Credits Log",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
