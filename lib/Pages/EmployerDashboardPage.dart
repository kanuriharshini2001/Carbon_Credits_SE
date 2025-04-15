import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class EmployerDashboardPage extends StatefulWidget {
  const EmployerDashboardPage({super.key});

  @override
  State<EmployerDashboardPage> createState() => _EmployerDashboardPageState();
}

class _EmployerDashboardPageState extends State<EmployerDashboardPage> {
  final DatabaseReference usersRef = FirebaseDatabase.instance.ref("users");
  final DatabaseReference redemptionsRef = FirebaseDatabase.instance.ref("redemptions");

  Map<String, dynamic> users = {};
  Map<String, List<Map<String, dynamic>>> redemptions = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final usersSnap = await usersRef.get();
      final redemptionsSnap = await redemptionsRef.get();

      final Map<String, dynamic> userMap = usersSnap.exists
          ? Map<String, dynamic>.from(usersSnap.value as Map)
          : {};

      final Map<String, List<Map<String, dynamic>>> redemptionMap = {};

      if (redemptionsSnap.exists) {
        final Map raw = redemptionsSnap.value as Map;
        for (var entry in raw.entries) {
          final String uid = entry.key;
          final Map redemptionGroup = Map.from(entry.value);

          redemptionMap[uid] = redemptionGroup.entries.map<Map<String, dynamic>>((e) {
            final val = Map<String, dynamic>.from(e.value);
            return {
              "reward": val["reward"]?.toString() ?? "Unknown",
              "status": val["status"]?.toString() ?? "Pending",
              "timestamp": val["timestamp"] ?? 0,
            };
          }).toList();
        }
      }

      setState(() {
        users = userMap;
        redemptions = redemptionMap;
        loading = false;
      });
    } catch (e) {
      print("Error loading data: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final approvedEmployees = users.entries.where((entry) {
      final user = Map<String, dynamic>.from(entry.value);
      return user['role'] == 'employee' && user['approved'] == true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Approved Employees & Redemptions"),
        backgroundColor: Colors.purple,
      ),
      body: approvedEmployees.isEmpty
          ? const Center(child: Text("No approved employees found."))
          : ListView.builder(
        itemCount: approvedEmployees.length,
        itemBuilder: (context, index) {
          final entry = approvedEmployees[index];
          final uid = entry.key;
          final user = Map<String, dynamic>.from(entry.value);
          final name = user['name']?.toString() ?? 'Unnamed';
          final email = user['email']?.toString() ?? 'No email';
          final userRedemptions = redemptions[uid] ?? [];

          return ExpansionTile(
            title: Text(name),
            subtitle: Text(email),
            children: userRedemptions.isEmpty
                ? [const ListTile(title: Text("No approved redemptions"))]
                : userRedemptions.map((r) {
              final timestamp = r["timestamp"];
              String formattedDate = "Unknown";
              if (timestamp is int && timestamp > 0) {
                final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
                formattedDate =
                "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
              }

              return ListTile(
                title: Text(r["reward"]),
                subtitle: Text("Status: ${r["status"]}"),
                trailing: Text(formattedDate),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
