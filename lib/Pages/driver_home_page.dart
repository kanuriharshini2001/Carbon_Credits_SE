import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'log_commute_page.dart';

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

    final snapshot = await FirebaseFirestore.instance
        .collection("commutes")
        .where("userId", isEqualTo: user.uid)
        .get();

    int sum = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data["creditsEarned"] != null) {
        sum += (data["creditsEarned"] as num).toInt();
      }
    }

    setState(() {
      totalCredits = sum;
    });
  }

  Widget _dashboardTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Total Credits: $totalCredits",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
              fetchTotalCredits(); // Refresh after logging a new commute
            },
          ),
        ],
      ),
    );
  }

  Widget _creditsLogTab() {
    final user = FirebaseAuth.instance.currentUser;
    final commuteRef = FirebaseFirestore.instance
        .collection("commutes")
        .where("userId", isEqualTo: user?.uid);

    return StreamBuilder<QuerySnapshot>(
      stream: commuteRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No commute records found."));
        }

        final entries = snapshot.data!.docs;

        return ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final commute = entries[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: const Icon(Icons.directions_bus),
              title: Text("${commute["mode"]} - ${commute["creditsEarned"]} credits"),
              subtitle: Text("Miles: ${commute["distance"]?.toStringAsFixed(2)}"),
              trailing: Text(commute["timestamp"]
                  .toDate()
                  .toString()
                  .split(' ')[0]),
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
              Navigator.popUntil(context, (route) => route.isFirst);
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
